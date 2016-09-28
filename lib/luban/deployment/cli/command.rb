module Luban
  module Deployment
    class Command < Luban::CLI::Command
      module Tasks
        module Provision
          Actions = %i(setup build destroy cleanup binstubs
                       show_current show_summary which whence)
          Actions.each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def provisionable?; true; end

          def provision_tasks; commands[:provision].commands; end

          protected

          def setup_provision_tasks
            _self = self
            command :provision do
              desc "Run provision tasks"

              task :setup do
                desc "Setup #{_self.display_name} environment"
                action! :setup
              end

              task :build do
                desc "Build #{_self.display_name} environment"
                switch :force, "Force to build", short: :f
                action! :build
              end

              task :destroy do
                desc "Destroy #{_self.display_name} environment"
                switch :force, "Force to destroy", short: :f, required: true
                action! :destroy
              end

              task :cleanup do
                desc "Clean up temporary files during installation"
                action! :cleanup
              end

              task :binstubs do
                desc "Update binstubs for required packages"
                switch :force, "Force to update binstubs", short: :f
                action! :binstubs
              end

              task :version do
                desc "Show current version for app/required packages"
                action! :show_current
              end

              task :versions do
                desc "Show app/package installation summary"
                action! :show_summary
              end

              task :which do
                desc "Show the real path for the given executable"
                argument :executable, "Executable to which"
                action! :which
              end

              task :whence do
                desc "List packages with the given executable"
                argument :executable, "Executable to whence"
                action! :whence
              end
            end
          end
        end

        module Deploy
          Actions = %i(deploy)
          Actions.each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def deployable?; true; end

          protected

          def setup_deploy_tasks
            task :deploy do
              desc "Run deployment"
              switch :force, "Force to deploy", short: :f
              action! :deploy
            end
          end
        end

        module Control
          Actions = %i(start_process stop_process kill_process
                       restart_process check_process show_process)
          Actions.each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def controllable?; true; end

          def control_tasks; commands[:control].commands; end

          protected

          def setup_control_tasks
            command :control do
              desc "Run process control tasks"

              task :start do
                desc "Start process"
                action! :start_process
              end

              task :stop do
                desc "Stop process"
                action! :stop_process
              end

              task :restart do
                desc "Restart process"
                action! :restart_process
              end

              task :kill do
                desc "Kill process forcely"
                action! :kill_process
              end

              task :status do
                desc "Check process status"
                action! :check_process
              end

              task :process do
                desc "Show running process if any"
                action! :show_process
              end
            end
          end
        end

        module Monitor
          Actions = %i(monitor_on monitor_off monitor_reload)
          Actions.each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def monitorable?
            controllable? and monitor_defined? and !monitor_itself?
          end

          def monitor_tasks; commands[:monitor].commands; end

          protected

          def setup_monitor_tasks
            command :monitor do
              desc "Run process monitoring tasks"
              task :on do
                desc "Turn on process monitor"
                action! :monitor_on
              end

              task :off do
                desc "Turn off process monitor"
                action! :monitor_off
              end

              task :reload do
                desc "Reload monitor configuration"
                action! :monitor_reload
              end
            end
          end
        end

        module Crontab
          Actions = %i(update_cronjobs list_cronjobs)
          Actions.each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def cronjobs; @cronjobs ||= []; end

          def has_cronjobs?; !cronjobs.empty?; end

          def cronjob(roles: nil, hosts: nil, **job)
            validate_cronjob(job)
            roles = Array(roles)
            hosts = Array(hosts)
            servers = select_servers(roles, hosts)
            servers.each { |s| server(s, cronjob: job) }
            cronjobs << job
          end

          def crontab_tasks; commands[:conjobs].commands; end

          protected

          def validate_cronjob(job)
            if job[:command].nil?
              abort "Aborted! Cron job command is MISSING."
            end
            if job[:schedule].nil?
              abort "Aborted! Cron job schedule is MISSING for command: #{job[:command]}"
            end
            if cronjobs.any? { |j| j[:command] == job[:command] }
              abort "Aborted! Duplicate command is FOUND: #{job[:command]}"
            end
          end

          def setup_crontab_tasks
            command :cronjobs do
              desc "Run crontab tasks"

              task :update do
                desc 'Update cron jobs'
                action! :update_cronjobs
              end

              task :list do
                desc 'List cron jobs'
                switch :all, "List all cron jobs"
                action! :list_cronjobs
              end
            end
          end
        end
      end

      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Helpers::Configuration
      include Luban::Deployment::Parameters::General

      def display_name; @display_name ||= name.camelcase; end

      def provisionable?; false; end
      def deployable?;    false; end
      def controllable?;  false; end
      def monitorable?;   false; end

      class << self
        def inherited(subclass)
          super
          # Ensure default_templates_paths from base class
          # got inherited to its subclasses
          paths = instance_variable_get('@default_templates_paths')
          subclass.instance_variable_set('@default_templates_paths', paths.nil? ? [] : paths.clone)
        end

        attr_reader :default_templates_paths

        def default_worker_class
          Luban::Deployment::Worker::Base
        end

        def worker_class(worker)
          class_name = worker.camelcase
          if const_defined?(class_name)
            const_get(class_name)
          else
            abort "Aborted! #{name}::#{class_name} is NOT defined."
          end
        end

        def dispatch_task(task, to:, as: task, locally: false, &blk)
          define_method(task) do |args:, opts:|
            run_task(cmd: as, args: args, opts: opts, locally: locally,
                     worker_class: self.class.worker_class(to), &blk)
          end

          protected task
        end
      end

      def run_task(cmd: nil, args:, opts:, locally: false,
                   worker_class: self.class.default_worker_class, &blk)
        backtrace = opts[:backtrace]
        task_args = compose_task_arguments(args)
        task_opts = compose_task_options(opts)
        run_opts = extract_run_options(task_opts)
        run_opts[:hosts] = :local if locally
        task_msg = { cmd: cmd, config: config, local: locally,
                     args: task_args, opts: task_opts}
        result = []
        mutex = Mutex.new
        run(**run_opts) do |backend|
          begin 
            r = worker_class.new(task_msg.merge(backend: backend), &blk).run
          rescue StandardError => e
            r = {
              hostname: backend.host.hostname,
              status: :failed,
              message: backtrace ? "#{e.message}\n#{e.backtrace.join("\n")}" : e.message,
              error: e
            }
          end
          mutex.synchronize { result << r }
        end
        print_task_result(result) if opts[:format] == :blackhole
        locally ? result.first[:__return__] : result
      end

      def base_templates_path(base_path)
        path = Pathname.new(base_path).dirname.join('templates')
        path.exist? ? path.realpath : nil
      end

      def default_templates
        return @default_templates unless @default_templates.nil?
        (@default_templates = []).tap do |t|
          default_templates_paths.each { |p| t.concat(p.children).uniq! }
        end
      end

      def default_templates_paths; self.class.default_templates_paths; end

      protected

      def on_configure
        super
        set_parameters
        set_default_parameters
        load_configuration
        validate_parameters
        load_libraries
        include_default_templates_path
        setup_cli
      end

      def set_parameters
        copy_parameters_from_parent(
          :luban_roles, :luban_root_path, :user,
          :stages, :applications, :work_dir, :apps_path
        )
      end

      def copy_parameters_from_parent(*parameters)
        parameters.each do |p| 
          if parent.respond_to?(p)
            send(p, parent.send(p))
          else
            abort "Aborted! #{self.class.name} failed to copy parameter #{p.inspect} from #{parent.class.name}."
          end
        end
      end

      def set_default_parameters
        set_default_general_parameters
      end

      def load_configuration; end

      def validate_parameters
        validate_general_parameters
      end

      def load_libraries; end

      def include_default_templates_path; end

      def setup_cli
        setup_descriptions
        setup_tasks
      end

      def setup_descriptions; end

      def setup_tasks
        setup_provision_tasks if provisionable?
        setup_deploy_tasks if deployable?
        setup_control_tasks if controllable?
        setup_monitor_tasks if monitorable?
      end

      %i(install deploy control).each do |action|
        define_method("setup_#{action}_tasks") do
          raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
        end
      end

      def add_common_task_options(task)
        task.switch :dry_run, "Run as a simulation", short: :d
        task.switch :once, "Run ONLY once", short: :o
        task.option :roles, "Run with given roles", 
                    type: :symbol, multiple: true, default: luban_roles
        task.option :hosts, "Run with given hosts", multiple: true, default: []
        task.option :in, "Run in parallel, sequence or group", short: :i, 
                    type: :symbol, within: [:parallel, :sequence, :groups], default: :parallel
        task.option :wait, "Wait interval for every run in sequence or groups", short: :w,
                    type: :integer, assure: ->(v){ v > 0 }, default: 2
        task.option :limit, "Number of hosts per group", short: :n,
                    type: :integer, assure: ->(v){ v > 0 }, default: 2
        task.option :format, "Set output format", short: :F,
                    type: :symbol, within: %i(pretty dot simpletext blackhole airbrussh),
                    default: :blackhole
        task.option :verbosity, "Set verbosity level", short: :V,
                    type: :symbol, within: Luban::Deployment::Helpers::Utils::LogLevels,
                    default: :info
        task.switch :backtrace, "Enable backtrace for exceptions", short: :B
      end

      def extract_run_options(task_opts)
        %i(once roles hosts in wait limit
           dry_run format verbosity).inject({}) do |opts, n| 
          opts[n] = task_opts.delete(n) if task_opts.has_key?(n)
          opts
        end
      end

      def compose_task_arguments(args); args.clone; end
      def compose_task_options(opts); opts.clone; end

      def run(roles: luban_roles, hosts: nil, once: false,
              dry_run: false, format:, verbosity:, **opts)
        configure_backend(dry_run: dry_run, format: format, verbosity: verbosity)
        hosts = Array(hosts)
        servers = select_servers(roles, hosts)
        servers = servers.first if once and !servers.empty?
        on(servers, **opts) { |backend| yield backend }
      end

      def select_servers(roles, hosts)
        hosts.empty? ? release_roles(*roles) : hosts
      end

      def on(hosts, **opts, &blk)
        SSHKit::Coordinator.new(hosts).each(opts) { blk.call(self) }
      end

      def print_task_result(result)
        result.each do |entry|
          next if entry[:message].to_s.empty?
          entry[:message].split("\n").each do |msg|
            puts "  [#{entry[:hostname]}] #{msg}"
          end
        end
      end

      def backend_configured?; @@backend_configured ||= false; end

      def configure_backend(dry_run:, format:, verbosity:)
        return if backend_configured?
        enable_dry_run if dry_run

        SSHKit.configure do |sshkit|
          sshkit.format           = format unless format == :airbrussh
          sshkit.output_verbosity = verbosity
          sshkit.default_env      = default_env
          sshkit.backend          = sshkit_backend
          sshkit.backend.configure do |backend|
            backend.pty                = pty
            backend.connection_timeout = connection_timeout
            if backend.respond_to?(:ssh_options)
              backend.ssh_options        = 
                backend.ssh_options.merge(user: user).merge!(ssh_options)
            end
          end
        end

        configure_airbrussh if format == :airbrussh
        @@backend_configured = true
      end

      def configure_airbrussh
        require 'airbrussh'
        Airbrussh.configure do |config|
          config.command_output = [:stdout, :stderr]
        end
        SSHKit.config.output = Airbrussh::Formatter.new($stdout)
      end

      def enable_dry_run
        sshkit_backend SSHKit::Backend::Printer
      end
    end
  end
end
