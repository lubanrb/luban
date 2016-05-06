module Luban
  module Deployment
    class Project < Luban::Deployment::Command
      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Parameters::Project
      include Luban::Deployment::Command::Tasks::Install
      include Luban::Deployment::Command::Tasks::Deploy
      include Luban::Deployment::Command::Tasks::Control

      attr_reader :apps

      def display_name; @display_name ||= "#{stage} #{project.camelcase}"; end

      def package_users_for(package_name, package_version, exclude: [], servers: [])
        apps.values.inject([]) do |package_users, app|
          if !exclude.include?(app.name) and
              app.use_package?(package_name, package_version, servers: servers)
            package_users << app.display_name
          end
          package_users
        end
      end

      def password_for(user)
        @passwords_mutex.synchronize do
          if @passwords[user].nil?
            @passwords[user] = ask(prompt: "Password for #{user}", echo: false)
          end
          @passwords[user]
        end
      end

      %i(installable? deployable? controllable?).each do |method|
        define_method(method) do
          apps.values.any? { |app| app.send(__method__) }
        end
      end

      (Luban::Deployment::Command::Tasks::Install::Actions | %i(destroy_project)).each do |action|
        define_method(action) do |args:, opts:|
          apps.each_value do |app|
            app.send(__method__, args: args, opts: opts) if app.installable?
          end
        end
      end

      alias_method :destroy, :destroy_project

      Luban::Deployment::Command::Tasks::Deploy::Actions.each do |action|
        define_method(action) do |args:, opts:|
          apps.each_value do |app|
            app.send(__method__, args: args, opts: opts) if app.deployable?
          end
        end
      end

      Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
        define_method(action) do |args:, opts:|
          apps.each_value do |app|
            app.send(__method__, args: args, opts: opts) if app.controllable?
          end
        end
      end

      protected

      def validate_parameters
        super
        validate_project_parameters
      end

      def set_default_parameters
        super
        set_default :stage, self.class.name.split('::').first.snakecase
        set_default :project, self.class.name.split('::').last.snakecase
        set_default_project_parameters
        @passwords = {}
        @passwords_mutex = Mutex.new
      end

      def load_libraries
        applications.each do |app|
          require "#{work_dir}/apps/#{app}/lib/application"
        end
      end

      def application_base_class(app)
        Object.const_get("#{project}:#{app}".camelcase)
      end

      def setup_cli
        setup_applications
        super
      end

      def setup_descriptions
        desc "Manage apps in #{display_name}"
      end

      def setup_applications
        @apps = {}
        applications.map(&:to_sym).each do |app|
          @apps[app] = command(app, base: application_base_class(app))
        end
      end
    end
  end
end