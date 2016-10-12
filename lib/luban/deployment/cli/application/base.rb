module Luban
  module Deployment
    class Application < Luban::Deployment::Command
      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Parameters::Project
      include Luban::Deployment::Parameters::Application
      include Luban::Deployment::Command::Tasks::Provision
      include Luban::Deployment::Command::Tasks::Deploy
      include Luban::Deployment::Command::Tasks::Control
      include Luban::Deployment::Command::Tasks::Monitor
      include Luban::Deployment::Command::Tasks::Crontab

      attr_reader :packages
      attr_reader :services
      attr_reader :current_app
      attr_reader :release_opts
      attr_reader :current_profile
      attr_reader :profile_opts

      def self.action_on_packages(action, as: action)
        define_method(action) do |args:, opts:|
          packages.each_value { |p| p.send(as, args: args, opts: opts) }
        end
        protected action
      end

      def self.action_on_services(action, as: action)
        define_method(action) do |args:, opts:|
          services.each_value { |s| s.send(as, args: args, opts: opts) }
        end
        protected action
      end

      def self.application_action(action, dispatch_to: nil, as: action, locally: false, &blk)
          define_method(action) do |args:, opts:|
            if current_app
              send("#{__method__}!", args: args, opts: opts.merge(version: current_app))
            else
              abort "Aborted! No current version of #{display_name} is specified."
            end
          end
          unless dispatch_to.nil?
            dispatch_task "#{action}!", to: dispatch_to, as: as, locally: locally, &blk
            protected "#{action}!"
          end
        end
      
      def find_project; parent; end
      def find_application(name = nil)
        name.nil? ? self : find_project.apps[name.to_sym]
      end

      def has_source?;   !source.empty?; end
      def has_profile?;  !profile.empty?; end
      def has_packages?; !packages.empty?; end
      def has_services?; !services.empty?; end

      def provisionable?;  has_packages?; end
      def deployable?; true; end
      def controllable?; has_source? or has_services?; end

      def use_package?(package_name, package_version, servers: [])
        package_name = package_name.to_sym
        packages.has_key?(package_name) and
        packages[package_name].has_version?(package_version) and
        packages[package_name].config.servers.any? { |s| servers.include?(s) }
      end

      def other_package_users_for(package_name, package_version, servers: [])
        find_project.package_users_for(package_name, package_version, 
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
        pkg.update_package_options(version, opts.merge(packages: packages))
        services[name] = pkg if pkg.is_a?(Luban::Deployment::Service::Base)
        packages[name] = pkg
      end
      alias_method :require_package, :package

      def bundle_via(ruby:, project: "uber")
        bundle_cmd = luban_root_path.join("env", "#{stage}.#{project}", ".luban", "pkg",
                                          "ruby", "versions", ruby.to_s.downcase, 'bin', 'bundle')
        set :bundle_via, bundle_cmd
      end

      def profile(from = nil, **opts)
        from.nil? ? @profile : (@profile = opts.merge(type: 'profile', from: from))
      end

      def profile_release(version, **opts)
        @current_profile = version if opts[:current]
        profile_opts[version] = opts.merge(version: version)
      end

      def source(from = nil, **opts)
        from.nil? ? @source : (@source = opts.merge(type: 'app', from: from))
      end

      def release(version, **opts)
        @current_app = version if opts[:current]
        release_opts[version] = opts.merge(version: version)
      end

      def default_source_path
        @default_source_path ||= config_finder[:application].stage_config_path.join('app')
      end

      def default_source?
        has_source? and source[:from] == default_source_path
      end

      def has_version?(version)
        release_opts.has_key?(version)
      end

      def versions; release_opts.keys; end
      def deprecated_versions; release_opts.select {|r, o| o[:deprecated] }.keys; end
      def deployable_versions; release_opts.select {|r, o| !o[:deprecated] }.keys; end

      def password_for(user); find_project.password_for(user); end

      def promptless_authen(args:, opts:)
        opts = opts.merge(app: self, public_keys: Array(public_key!(args: args, opts: opts)))
        public_keys = promptless_authen!(args: args, opts: opts).collect { |r| r[:public_key] }
        opts = opts.merge(roles: [scm_role, archive_role])
        promptless_authen!(args: args, opts: opts)
        opts = opts.merge(roles: [archive_role], public_keys: public_keys)
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

      %i(install_all uninstall_all binstubs which whence).each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          send("#{action}!", args: args, opts: opts)
        end
        action_on_packages("#{action}!", as: action)
      end

      def cleanup(args:, opts:)
        show_app_environment
        cleanup_packages!(args: args, opts: opts)
        cleanup_application!(args: args, opts: opts)
      end
      action_on_packages :cleanup_packages!, as: :cleanup
      dispatch_task :cleanup_application!, to: :constructor, as: :cleanup

      %i(show_current show_summary).each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          send("#{action}_packages!", args: args, opts: opts)
          send("#{action}_application", args: args, opts: opts) if has_source?
        end
        action_on_packages "#{action}_packages!", as: action
      end

      def show_current_application(args:, opts:)
        print_summary(get_summary(args: args, opts: opts.merge(version: current_app)))
      end

      def show_summary_application(args:, opts:)
        versions.each do |version|
          print_summary(get_summary(args: args, opts: opts.merge(version: version)))
        end
      end
      dispatch_task :get_summary, to: :controller, as: :get_summary

      def deploy(args:, opts:)
        show_app_environment
        deploy_release(args: args, opts: opts) if has_source?
        deploy_profile(args: args, opts: opts) if has_profile?
        deploy_cronjobs(args: args, opts: opts)
      end

      (Luban::Deployment::Command::Tasks::Control::Actions |
       Luban::Deployment::Command::Tasks::Monitor::Actions).each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          send("service_#{action}!", args: args, opts: opts)
          send("application_#{action}", args: args, opts: opts) if has_source?
        end
        action_on_services "service_#{action}!", as: action
        application_action "application_#{action}", dispatch_to: :controller, as: action
      end

      def init_profiles(args:, opts:)
        show_app_environment
        init_profile(args: args, opts: opts)
        init_service_profiles(args: args, opts: opts)
        init_source(args: args, opts: opts)
      end

      def init_source(args:, opts:)
        if default_source?
          init_source!(args: args, opts: opts.merge(source: source))
        end
      end
      dispatch_task :init_source!, to: :configurator, as: :init_source, locally: true

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
          services.each_value { |s| s.init_profile(args: args, opts: opts) }
        end
      end

      Luban::Deployment::Command::Tasks::Crontab::Actions.each do |action|
        define_method(action) do |args:, opts:|
          show_app_environment
          opts = opts.merge(version: current_app) if current_app
          send("#{action}!", args: args, opts: opts)
        end
        dispatch_task "#{action}!", to: :crontab, as: action
        protected "#{action}!" 
      end

      protected

      def set_parameters
        super
        copy_parameters_from_parent(:stage, :project, :process_monitor)
        @packages = {}
        @services = {}
        @source = {}
        @release_opts = {}
        @profile = {}
        @profile_opts = {}
      end

      def validate_parameters
        super
        validate_project_parameters
        validate_application_parameters
      end

      def set_default_parameters
        super
        set_default_project_parameters
        set_default :application, self.class.name.split(':').last.snakecase
        set_default_application_parameters
        set_default_profile
      end

      def set_default_source
        source(default_source_path, scm: :rsync)
        release(stage, current: true)
      end

      def set_default_profile
        if config_finder[:application].has_profile?
          profile(config_finder[:application].stage_profile_path, scm: :rsync)
          profile_release(stage, current: true)
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
        setup_crontab_tasks
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
          version = o[:version]
          unless version.nil?
            o.merge!(release: release_opts[version])
            update_release_tag(o)
          end
        end
      end

      def update_release_tag(version:, **opts)
        opts[:release][:tag] ||=
          release_tag(args: {}, opts: opts.merge(repository: source.merge(version: version)))
      end
      dispatch_task :release_tag, to: :repository, as: :release_tag, locally: true

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
        deploy_profile!(args: args, opts: opts.merge(repository: profile.merge(version: current_profile)))
      end

      def update_profile(args:, opts:)
        update_profile!(args: args, opts: opts.merge(version: current_app))
        services.each_value { |s| s.send(:update_profile, args: args, opts: opts) }
      end
      dispatch_task :update_profile!, to: :configurator, as: :update_profile, locally: true

      def deploy_release(args:, opts:)
        deployable_versions.each do |version|
          deploy_release!(args: args, opts: opts.merge(repository: source.merge(version: version)))
        end
        deprecated_versions.each do |version|
          deprecate_release!(args: args, opts: opts.merge(repository: source.merge(version: version)))
        end
      end

      def deploy_release!(args:, opts:)
        package_release!(args: args, opts: opts)[:release_pack].tap do |pack|
          unless pack.nil?
            publish_release!(args: args, opts: opts.merge(release_pack: pack))
          end
        end
      end
      alias_method :deploy_profile!, :deploy_release!
      dispatch_task :package_release!, to: :repository, as: :package, locally: true
      dispatch_task :publish_release!, to: :publisher, as: :publish

      def deprecate_release!(args:, opts:)
        deprecate_packaged_release!(args: args, opts: opts)[:release_pack].tap do |pack|
          unless pack.nil?
            deprecate_published_release!(args: args, opts: opts.merge(release_pack: pack))
          end
        end
      end
      dispatch_task :deprecate_packaged_release!, to: :repository, as: :deprecate, locally: true
      dispatch_task :deprecate_published_release!, to: :publisher, as: :deprecate

      def deploy_cronjobs(args:, opts:)
        opts = opts.merge(version: current_app) if has_source?
        deploy_cronjobs!(args: args, opts: opts)
      end
      dispatch_task :deploy_cronjobs!, to: :crontab, as: :deploy_cronjobs

      def print_summary(result)
        result.each do |entry|
          s = entry[:summary]
          puts "  [#{entry[:hostname]}] #{s[:status]} #{s[:name]} (#{s[:published]})"
          puts "  [#{entry[:hostname]}]    #{s[:alert]}" unless s[:alert].nil?
        end
      end
    end
  end
end
