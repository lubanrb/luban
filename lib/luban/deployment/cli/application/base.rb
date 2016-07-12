module Luban
  module Deployment
    class Application < Luban::Deployment::Command
      include Luban::Deployment::Parameters::Project
      include Luban::Deployment::Parameters::Application
      include Luban::Deployment::Command::Tasks::Install
      include Luban::Deployment::Command::Tasks::Deploy
      include Luban::Deployment::Command::Tasks::Control

      attr_reader :packages
      attr_reader :services

      def has_source?;   !source.empty?; end
      def has_profile?;  !profile.empty?; end
      def has_packages?; !packages.empty?; end
      def has_services?; !services.empty?; end

      def installable?;  has_source? or has_packages?; end
      def deployable?;   has_source?  or has_profile? or has_services?; end
      def controllable?; has_source? or has_profile? or has_services?; end

      def use_package?(package_name, package_version, servers: [])
        package_name = package_name.to_sym
        packages.has_key?(package_name) and
        packages[package_name].has_version?(package_version) and
        packages[package_name].config.servers.any? { |s| servers.include?(s) }
      end

      def other_package_users_for(package_name, package_version, servers: [])
        parent.package_users_for(package_name, package_version, 
                                 exclude: [name], servers: servers)
      end

      def package(name, version:, **opts)
        yield opts if block_given?
        name = name.to_sym
        pkg = if has_command?(name)
                commands[name]
              else
                command(name, base: Luban::Deployment::Package::Base.package_class(name))
              end
        pkg.update_package_options(version, opts)
        services[name] = pkg if pkg.is_a?(Luban::Deployment::Service::Base)
        packages[name] = pkg
      end
      alias_method :require_package, :package

      def source(from = nil, **opts)
        return @source if from.nil?
        @source = opts.merge(type: 'app', from: from)
        if source_version.nil?
          abort "Aborted! Please specify the source version with :tag, :branch or :ref." 
        end
        @source 
      end

      def source_version
        @source[:tag] || @source[:branch] || @source[:ref]
      end

      def profile(from = nil, **opts)
        from.nil? ? @profile : (@profile = opts.merge(type: 'profile', from: from))
      end

      def password_for(user); parent.password_for(user); end

      def promptless_authen(args:, opts:)
        opts = opts.merge(app: self, public_keys: Array(public_key!(args: args, opts: opts)))
        opts[:roles] << scm_role unless scm_role.nil?
        promptless_authen!(args: args, opts: opts)
      end
      dispatch_task :public_key!, to: :authenticator, as: :public_key, locally: true
      dispatch_task :promptless_authen!, to: :authenticator, as: :promptless_authen

      def setup(args:, opts:)
        show_app_environment
        promptless_authen(args: args, opts: opts)
        setup!(args: args, opts: opts)
      end
      dispatch_task :setup!, to: :constructor, as: :setup

      def build(args:, opts:)
        show_app_environment
        install_all!(args: args, opts: opts)
        build_repositories(args: args, opts: opts)
      end

      def destroy(args:, opts:)
        uninstall_all!(args: args, opts: opts)
        destroy!(args: args, opts: opts)
      end

      def destroy_project(args:, opts:)
        show_app_environment
        destroy!(args: args, opts: opts.merge(destroy_project: true))
      end
      dispatch_task :destroy!, to: :constructor, as: :destroy

      %i(install_all uninstall_all).each do |action|
        define_method("#{action}!") do |args:, opts:|
          packages.each_value { |p| p.send(action, args: args, opts: opts) }
        end
        protected "#{action}!"
      end

      (Luban::Deployment::Command::Tasks::Install::Actions - %i(setup build destroy)).each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          send("#{action}!", args: args, opts: opts)
        end

        define_method("#{action}!") do |args:, opts:|
          packages.each_value { |p| p.send(action, args: args, opts: opts) }
        end
        protected "#{action}!"
      end

      { show_current: :controller, show_summary: :controller,
        cleanup: :constructor }.each_pair do |action, worker|
        alias_method "#{action}_packages!", "#{action}!" 
        define_method("#{action}!") do |args:, opts:|
          send("#{action}_application!", args: args, opts: opts) if has_source?
          send("#{action}_packages!", args: args, opts: opts)
        end
        protected "#{action}!"
        dispatch_task "#{action}_application!", to: worker, as: action
      end

      def deploy(args:, opts:)
        show_app_environment
        if has_source?
          release = deploy_release(args: args, opts: opts)
          opts = opts.merge(release: release)
        end
        deploy_profile(args: args, opts: opts) if has_profile?
      end

      Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          send("#{action}!", args: args, opts: opts)
        end

        define_method("#{action}!") do |args:, opts:|
          send("application_#{action}!", args: args, opts: opts) if has_source?
          send("service_#{action}!", args: args, opts: opts)
        end
        protected "#{action}!"

        dispatch_task "application_#{action}!", to: :controller, as: action

        define_method("service_#{action}!") do |args:, opts:|
          services.each_value { |s| s.send(action, args: args, opts: opts) }
        end
        protected "service_#{action}!"
      end

      def init_profiles(args:, opts:)
        show_app_environment
        init_profile(args: args, opts: opts)
        init_service_profiles(args: args, opts: opts)
      end

      def init_profile(args:, opts:)
        if opts[:app] or opts[:service].nil?
          init_profile!(args: args, opts: opts.merge(default_templates: default_templates))
        end
      end
      dispatch_task :init_profile!, to: :configurator, as: :init_profile, locally: true

      def init_service_profiles(args:, opts:)
        return if opts[:app]
        if services.has_key?(opts[:service])
          services[opts[:service]].init_profile(args: args, opts: opts)
        else
          services.values.each { |s| s.init_profile(args: args, opts: opts) }
        end
      end

      protected

      def set_parameters
        super
        copy_parameters_from_parent(:stage, :project, :process_monitor)
        @packages = {}
        @services = {}
        @source = {}
        @profile = {}
      end

      def validate_parameters
        super
        validate_project_parameters
        validate_application_parameters
      end

      def set_default_parameters
        super
        set_default_project_parameters
        set_default :application, self.class.name.split(':').last.downcase
        set_default_application_parameters
        set_default_profile
      end

      def set_default_application_parameters
        super
        linked_dirs.push('log', 'pids')
      end

      def set_default_profile
        if config_finder[:application].has_profile?
          profile(config_finder[:application].stage_profile_path, scm: :rsync) 
        end
      end

      def load_configuration
        config_finder[:project].load_configuration
        config_finder[:application].load_configuration
      end

      def setup_descriptions
        desc "Manage application #{display_name}"
        long_desc "Manage the deployment of application #{display_name} in #{parent.class.name}"
      end

      def setup_tasks
        setup_init_profiles
        super
      end

      def setup_init_profiles
        _services = services.keys
        task :init do
          desc 'Initialize deployment app/service profiles'
          switch :app, "Application profile ONLY", short: :a
          option :service, "Service profile ONLY", short: :s, nullable: true, 
                                                   within: _services.push(nil), type: :symbol
          action! :init_profiles
        end
      end

      def compose_task_options(opts)
        super.merge(name: name.to_s, packages: packages).tap do |o|
          o.merge!(version: source_version) if has_source?
        end
      end

      def show_app_environment
        puts "#{display_name} in #{parent.class.name}"
      end

      def build_repositories(args:, opts:)
        build_repository!(args: args, opts: opts.merge(repository: profile)) if has_profile?
        build_repository!(args: args, opts: opts.merge(repository: source)) if has_source?
      end
      dispatch_task :build_repository!, to: :repository, as: :build, locally: true

      def deploy_profile(args:, opts:)
        update_profile(args: args, opts: opts)
        deploy_profile!(args: args, opts: opts.merge(repository: profile))
      end

      def update_profile(args:, opts:)
        update_profile!(args: args, opts: opts)
        services.each_value { |s| s.send(:update_profile, args: args, opts: opts) }
      end
      dispatch_task :update_profile!, to: :configurator, as: :update_profile, locally: true

      def deploy_release(args:, opts:)
        deploy_release!(args: args, opts: opts.merge(repository: source)).tap do
          binstubs!(args: args, opts: opts)
        end
      end

      def deploy_release!(args:, opts:)
        package_release!(args: args, opts: opts)[:release].tap do |release|
          unless release.nil?
            publish_release!(args: args, opts: opts.merge(release: release))
          end
        end
      end
      alias_method :deploy_profile!, :deploy_release!
      dispatch_task :package_release!, to: :repository, as: :package, locally: true
      dispatch_task :publish_release!, to: :publisher, as: :publish
    end
  end
end