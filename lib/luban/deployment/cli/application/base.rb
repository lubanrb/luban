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
        from.nil? ? @source : (@source = opts.merge(name: 'app', from: from))
      end

      def profile(from = nil, **opts)
        from.nil? ? @profile : (@profile = opts.merge(name: 'profile', from: from))
      end

      def password_for(user); parent.password_for(user); end

      def promptless_authen(args:, opts:)
        opts = opts.merge(app: self, public_keys: Array(public_key!(args: args, opts: opts)))
        opts[:roles] << scm_role unless scm_role.nil?
        promptless_authen!(args: args, opts: opts)
      end

      def setup(args:, opts:)
        show_app_environment
        promptless_authen(args: args, opts: opts)
        build!(args: args, opts: opts)
      end

      def build(args:, opts:)
        show_app_environment
        install_all(args: args, opts: opts)
        build_repositories(args: args, opts: opts)
      end

      def destroy(args:, opts:)
        uninstall_all(args: args, opts: opts)
        destroy!(args: args, opts: opts)
      end

      %i(install_all uninstall_all).each do |action|
        define_method(action) do |args:, opts:|
          packages.each_value { |p| p.send(__method__, args: args, opts: opts) }
        end
      end

      (Luban::Deployment::Command::Tasks::Install::Actions - 
       %i(setup build destroy)).each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          packages.each_value { |p| p.send(__method__, args: args, opts: opts) }
        end
      end

      alias_method :cleanup_packages, :cleanup
      def cleanup(args:, opts:)
        cleanup_packages(args: args, opts: opts)
        cleanup!(args: args, opts: opts)
      end

      def destroy_project(args:, opts:)
        show_app_environment
        destroy!(args: args, opts: opts.merge(destroy_project: true))
      end

      def deploy(args:, opts:)
        show_app_environment
        deploy_profile(args: args, opts: opts) if has_profile?
        deploy_release(args: args, opts: opts) if has_source?
      end

      Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          services.each_value { |s| s.send(__method__, args: args, opts: opts) }
        end
      end

      def init_services(args:, opts:)
        show_app_environment
        service = args[:service]
        (service.nil? ? services.values : [services[service]]).each do |s|
          s.init_service(args: args, opts: opts)
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
        setup_init_services
        super
      end

      def setup_init_services
        return unless has_services?
        service_names = services.keys
        command :init do
          desc 'Initialize deployment services'
          argument :service, 'Service name', within: service_names, required: false, type: :symbol
          action! :init_services
        end
      end

      def show_app_environment
        puts "#{display_name} in #{parent.class.name}"
      end

      %i(build destroy cleanup).each do |task|
        dispatch_task "#{task}!", to: :builder, as: task
      end

      def build_repositories(args:, opts:)
        build_repository!(args: args, opts: opts.merge(repository: profile)) if has_profile?
        build_repository!(args: args, opts: opts.merge(repository: source)) if has_source?
      end

      def deploy_profile(args:, opts:)
        update_profile!(args: args, opts: opts)
        deploy_profile!(args: args, opts: opts.merge(repository: profile))
      end

      def update_profile!(args:, opts:)
        services.each_value { |s| s.send(:update_profile, args: args, opts: opts) }
      end

      def deploy_release(args:, opts:)
        deploy_release!(args: args, opts: opts.merge(repository: source))
      end

      def deploy_release!(args:, opts:)
        package_release!(args: args, opts: opts)[:release].tap do |release|
          unless release.nil?
            publish_release!(args: args, opts: opts.merge(release: release))
          end
        end
      end
      alias_method :deploy_profile!, :deploy_release!

      dispatch_task :promptless_authen!, to: :authenticator, as: :promptless_authen
      dispatch_task :public_key!, to: :authenticator, as: :public_key, locally: true
      dispatch_task :build_repository!, to: :repository, as: :build, locally: true
      dispatch_task :package_release!, to: :repository, as: :package, locally: true
      dispatch_task :publish_release!, to: :publisher, as: :publish
    end
  end
end