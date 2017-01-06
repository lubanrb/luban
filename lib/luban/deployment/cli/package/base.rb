module Luban
  module Deployment
    module Package
      class Base < Luban::Deployment::Command
        using Luban::CLI::CoreRefinements

        class << self
          def inherited(subclass)
            super
            # Ensure package dependencies from base class
            # got inherited to its subclasses

            subclass.instance_variable_set(
              '@dependencies',
              Marshal.load(Marshal.dump(dependencies))
            )
          end

          def dependencies
            @dependencies ||= DependencySet.new
          end

          def apply_to(version, &blk)
            dependencies.apply_to(version, &blk)
          end

          def required_packages_for(version)
            dependencies.dependencies_for(version)
          end

          def package_class(package)
            require_path = package_require_path(package)
            require require_path.to_s
            package_base_class(require_path)
          rescue LoadError => e
            abort "Aborted! Failed to load package #{require_path}: #{e.message}"
          end

          def worker_class(worker, package: self)
            if package.is_a?(Class)
              if package == self
                super(worker)
              else
                package.worker_class(worker)
              end
            else
              package_class(package).worker_class(worker)
            end
          end

          def decompose_version(version)
            { major_version: version, patch_level: '' }
          end

          def version_mutex; @version_mutex ||= Mutex.new; end

          def latest_version
            version_mutex.synchronize do
              @latest_version ||= get_latest_version
            end
          end

          def get_latest_version
            raise NotImplementedError, "#{self.class.name}#get_latest_version is an abstract method."
          end

          protected

          def package_require_path(package_name)
            package_require_root.join(package_name.to_s.gsub(':', '/'))
          end

          def package_require_root
            @default_package_root ||= Pathname.new("luban/deployment/packages")
          end

          def package_base_class(path)
            Object.const_get(path.to_s.camelcase, false)
          end
        end

        include Luban::Deployment::Parameters::Project
        include Luban::Deployment::Parameters::Application
        include Luban::Deployment::Command::Tasks::Provision

        def monitorable?; false; end

        def find_project; parent.parent; end
        def find_application(name = nil)
          name.nil? ? parent : find_project.apps[name.to_sym]
        end

        attr_reader :current_version

        def package_options; @package_options ||= {}; end

        def update_package_options(version, **opts)
          unless has_version?(version)
            version = self.class.package_class(name).latest_version if version == 'latest'
            package_options[version] = 
              { name: name.to_s }.merge!(self.class.decompose_version(version))
          end
          @current_version = version if opts[:current]
          package_options[version].merge!(opts)
        end

        def has_version?(version)
          package_options.has_key?(version)
        end

        def versions; package_options.keys; end

        dispatch_task :download_package, to: :installer, as: :download, locally: true
        dispatch_task :install_package, to: :installer, as: :install

        %i(uninstall cleanup_all update_binstubs
           get_summary which_current whence_origin).each do |task|
          dispatch_task task, to: :installer
        end

        def install(args:, opts:)
          result = download_package(args: args, opts: opts)
          unless result.nil? or result.status == :failed
            install_package(args: args, opts: opts)
          end
        end

        def install_all(args:, opts:)
          versions.each do |v| 
            install(args: args, opts: opts.merge(version: v))
          end
        end

        def uninstall_all(args:, opts:)
          versions.each do |v|
            uninstall(args: args, opts: opts.merge(version: v))
          end
        end

        alias_method :uninstall!, :uninstall
        def uninstall(args:, opts:)
          servers = select_servers(opts[:roles], opts[:hosts])
          apps = parent.other_package_users_for(name, opts[:version], servers: servers)
          if apps.empty? or opts[:force]
            uninstall!(args: args, opts: opts)
          else
            puts "Skipped. #{name}-#{opts[:version]} is being referenced by #{apps.join(', ')}. " +
                 "use -f to force uninstalling if necessary."
          end
        end

        def cleanup(args:, opts:)
          versions.each do |v|
            cleanup_all(args: args, opts: opts.merge(version: v))
          end
        end

        def binstubs(args:, opts:)
          if current_version
            update_binstubs(args: args, opts: opts.merge(version: current_version))
          else
            versions.each do |v|
              update_binstubs(args: args, opts: opts.merge(version: v))
            end
          end
        end

        def show_current(args:, opts:)
          if current_version
            print_summary(get_summary(args: args, opts: opts.merge(version: current_version)))
          else
            puts "    Warning! No current version of #{display_name} is specified."
          end
        end

        def show_summary(args:, opts:)
          versions.each do |v|
            print_summary(get_summary(args: args, opts: opts.merge(version: v)))
          end
        end

        def which(args:, opts:)
          if current_version
            print_summary(which_current(args: args, opts: opts.merge(version: current_version)))
          else
            puts "    Warning! No current version of #{display_name} is specified."
          end
        end

        def whence(args:, opts:)
          versions.each do |v|
            print_summary(whence_origin(args: args, opts: opts.merge(version: v)))
          end
        end

        protected

        def set_parameters
          self.config = parent.config
        end

        def setup_tasks
          super
          setup_provision_tasks
        end

        def compose_task_options(opts)
          opts = super
          version = opts[:version]
          unless version.nil?
            # Merge package options into task options without nil ones
            opts = package_options[version].merge(opts.reject { |_, v| v.nil? })
          end
          opts
        end

        def setup_descriptions
          desc "Manage package #{display_name}"
          long_desc "Manage the deployment of package #{display_name} in #{parent.class.name}"
        end

        def setup_provision_tasks
          super

          commands[:provision].undef_task :setup
          commands[:provision].undef_task :build
          commands[:provision].undef_task :destroy

          _package = self
          commands[:provision].alter do
            task :install do
              desc "Install a given version"
              long_desc "Install a given version in #{_package.parent.class.name}"
              option :version, "Version to install", short: :v, required: true,
                     assure: ->(v){ _package.versions.include?(v) }
              switch :force, "Force to install", short: :f
              action! :install
            end

            task :install_all do
              desc "Install all versions"
              long_desc "Install all versions in #{_package.parent.class.name}"
              switch :force, "Force to install", short: :f
              action! :install_all
            end

            task :uninstall do
              desc "Uninstall a given version"
              long_desc "Uninstall a given version in #{_package.parent.class.name}"
              option :version, "Version to uninstall", short: :v, required: true,
                      assure: ->(v){ _package.versions.include?(v) }
              switch :force, "Force to uninstall", short: :f
              action! :uninstall
            end

            task :uninstall_all do
              desc "Uninstall all versions"
              long_desc "Uninstall all versions in #{_package.parent.class.name}"
              switch :force, "Force to uninstall", short: :f, required: true
              action! :uninstall_all
            end
          end
        end

        def print_summary(result)
          result.each do |entry|
            s = entry[:summary]
            puts "  [#{entry[:hostname]}] #{s[:status]} #{s[:name]} (#{s[:installed]})"
            puts "  [#{entry[:hostname]}]      #{s[:executable]}" unless s[:executable].nil?
            puts "  [#{entry[:hostname]}]    #{s[:alert]}" unless s[:alert].nil?
          end
        end
      end
    end
  end
end
