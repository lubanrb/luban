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
        services[name] = pkg if pkg.is_a?(Luban::Deployment::Package::Service)
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

      def build(args:, opts:)
        show_app_environment
        promptless_authen(args: args, opts: opts)
        build!(args: args, opts: opts)
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

      %i(cleanup binstubs show_current show_summary which whence).each do |action|
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
        deploy_releases(args: args, opts: opts)
      end

      protected

      def set_parameters
        super
        copy_parameters_from_parent(:stage, :project)
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
        profile_path = config_finder[:application].stage_config_path.join('profile')
        profile(profile_path, scm: :rsync) if profile_path.directory?
      end

      def load_configuration
        config_finder[:project].load_configuration
        config_finder[:application].load_configuration
      end

      def setup_descriptions
        desc "Manage application #{display_name}"
        long_desc "Manage the deployment of application #{display_name} in #{parent.class.name}"
      end

      def show_app_environment
        puts "#{display_name} in #{parent.class.name}"
      end

      %i(build destroy cleanup).each do |m|
        define_task_method("#{m}!", task: m, worker: :builder)
      end

      def build_repositories(args:, opts:)
        build_repository!(args: args, opts: opts.merge(repository: profile)) if has_profile?
        build_repository!(args: args, opts: opts.merge(repository: source)) if has_source?
      end

      def deploy_releases(args:, opts:)
        deploy_release(args: args, opts: opts.merge(repository: profile)) if has_profile?
        deploy_release(args: args, opts: opts.merge(repository: source)) if has_source?
      end

      def deploy_release(args:, opts:)
        package_release!(args: args, opts: opts)[:release].tap do |release|
          unless release.nil?
            publish_release!(args: args, opts: opts.merge(release: release))
          end
        end
      end

      define_task_method("promptless_authen!", task: :promptless_authen, worker: :authenticator)
      define_task_method("public_key!", task: :public_key, worker: :authenticator, locally: true)
      define_task_method("build_repository!", task: :build, worker: :repository, locally: true)
      define_task_method("package_release!", task: :package, worker: :repository, locally: true)
      define_task_method("publish_release!", task: :publish, worker: :publisher)
    end
  end
end