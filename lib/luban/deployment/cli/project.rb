module Luban
  module Deployment
    class Project < Luban::Deployment::Command
      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Parameters::Project
      include Luban::Deployment::Command::Tasks::Provision
      include Luban::Deployment::Command::Tasks::Deploy
      include Luban::Deployment::Command::Tasks::Control
      include Luban::Deployment::Command::Tasks::Monitor

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

      %i(provisionable? deployable? controllable? monitorable?).each do |method|
        define_method(method) do
          apps.values.any? { |app| app.send(__method__) }
        end
      end

      (Luban::Deployment::Command::Tasks::Provision::Actions | %i(destroy_project)).each do |action|
        define_method(action) do |args:, opts:|
          apps.each_value do |app|
            app.send(__method__, args: args, opts: opts) if app.provisionable?
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

      #Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
      #  define_method(action) do |args:, opts:|
      #    apps.each_value do |app|
      #      app.send(__method__, args: args, opts: opts) if app.controllable?
      #    end
      #  end
      #end

      def start_sequence; @start_sequence ||= apps.keys; end
      def stop_sequence; @stop_sequence ||= start_sequence.reverse; end

      %i(start_process restart_process check_process show_process).each do |action|
        define_method(action) do |args:, opts:|
          start_sequence.each do |app|
            apps[app].send(__method__, args: args, opts: opts) if apps[app].controllable?
          end
        end
      end

      %i(stop_process kill_process).each do |action|
        define_method(action) do |args:, opts:|
          stop_sequence.each do |app|
            apps[app].send(__method__, args: args, opts: opts) if apps[app].controllable?
          end
        end
      end

      Luban::Deployment::Command::Tasks::Monitor::Actions.each do |action|
        define_method(action) do |args:, opts:|
          apps.each_value do |app|
            app.send(__method__, args: args, opts: opts) if app.monitorable?
          end
        end
      end

      def init_application(args:, opts:)
        singleton_class.send(:include, Luban::Deployment::Helpers::Generator::Application)
        define_singleton_method(:application) { args[:application] }
        create_application_skeleton
      end

      protected

      def set_parameters
        super
        set :stage, self.class.name.split('::').first.snakecase
        set :project, self.class.name.split('::').last.snakecase
      end

      def set_default_parameters
        super
        @passwords = {}
        @passwords_mutex = Mutex.new
      end

      def load_libraries
        applications.each do |app|
          require "#{apps_path}/#{app}/lib/application"
        end
      end

      def application_base_class(app)
        Object.const_get("#{project}:#{app}".camelcase)
      end

      def setup_cli
        setup_applications
        setup_init_application
        super
      end

      def setup_descriptions
        desc "Manage apps in #{display_name}"
      end

      def setup_applications
        @apps = {}
        applications.map(&:to_sym).each do |app|
          if application_initialized?(app)
            @apps[app] = command(app, base: application_base_class(app))
          end
        end
      end

      def setup_init_application
        command :init do
          desc 'Initialize a Luban deployment application'
          argument :application, 'Application name', required: true
          action! :init_application
        end
      end

      def application_initialized?(app)
        File.file?("#{apps_path}/#{app}/config/deploy/#{stage}.rb")
      end
    end
  end
end
