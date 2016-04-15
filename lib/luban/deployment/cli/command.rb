module Luban
  module Deployment
    class Command < Luban::CLI::Command
      module Tasks
        module Install
          %i(build destroy cleanup binstubs
             show_current show_summary which whence).each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def installable?; true; end

          protected

          def setup_install_tasks
            _self = self
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
              desc "Show current version for required packages"
              action! :show_current
            end

            task :versions do
              desc "Show package installation summary"
              action! :show_summary
            end

            task :which do
              desc "Show the real path for the given executable"
              argument :executable, "Executable to which", short: :e, required: true
              action! :which
            end

            task :whence do
              desc "List packages with the given executable"
              argument :executable, "Executable to whence", short: :e, required: true
              action! :whence
            end
          end
        end

        module Deploy
          %i(deploy).each do |action| 
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def deployable?; true; end

          protected

          def setup_deploy_tasks
            task :deploy do
              desc "Run deployment"
              action! :deploy
            end
          end
        end

        module Control
          %i(start_process stop_process restart_process
             show_process_status test_process 
             monitor_process unmonitor_process).each do |action|
            define_method(action) do |args:, opts:|
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def controllable?; true; end

          protected

          def setup_control_tasks
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

            task :status do
              desc "Show process status"
              action! :show_process_status
            end

            task :test do
              desc "Test process"
              action! :test_process
            end

            task :monitor do
              desc "Turn on process monitor"
              action! :monitor_process
            end

            task :unmonitor do
              desc "Turn off process monitor"
              action! :unmonitor_process
            end
          end
        end
      end

      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Helpers::Configuration
      include Luban::Deployment::Parameters::General

      def display_name; @display_name ||= name.camelcase; end

      def installable?;  false; end
      def deployable?;   false; end
      def controllable?; false; end

      def task(cmd, **opts, &blk)
        command(cmd, **opts, &blk).tap do |c|
        add_common_task_options(c)
          if !c.summary.nil? and c.description.empty?
            c.long_desc "#{c.summary} in #{self.class.name}"
          end
        end
      end

      alias_method :undef_task, :undef_command

      class << self
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

        def define_task_method(method, task: method, worker:, locally: false, &blk)
          define_method(method) do |args:, opts:|
            run_task(cmd: task, args: args, opts: opts, locally: locally,
                     worker_class: self.class.worker_class(worker), &blk)
          end
        end
      end

      def run_task(cmd: nil, args:, opts:, locally: false,
                   worker_class: self.class.default_worker_class, &blk)
        backtrace = opts.delete(:backtrace)
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
              status: :failed,
              message: backtrace ? "#{e.message}\n#{e.backtrace.join("\n")}" : e.message,
              error: e
            }
          end
          mutex.synchronize { result << r }
        end
        print_task_result result
        locally ? result.first[:__return__] : result
      end

      protected

      def on_configure
        super
        set_parameters
        set_default_parameters
        load_configuration
        validate_parameters
        load_libraries
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

      def setup_cli
        setup_descriptions
        setup_tasks
      end

      def setup_descriptions; end

      def setup_tasks
        setup_install_tasks if installable?
        setup_deploy_tasks if deployable?
        setup_control_tasks if controllable?
      end

      %i(install deploy control).each do |operation|
        define_method("setup_#{operation}_tasks") do
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
              dry_run: false, format: log_format, verbosity: log_level, **opts)
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
          puts "  [#{entry[:hostname]}] #{entry[:message]}"
        end
      end

      def backend_configured?; @@backend_configured ||= false; end

      def configure_backend(dry_run:, format:, verbosity:)
        return if backend_configured?
        enable_dry_run if dry_run

        SSHKit.configure do |sshkit|
          sshkit.format           = format
          sshkit.output_verbosity = verbosity
          sshkit.default_env      = default_env
          sshkit.backend          = sshkit_backend
          sshkit.backend.configure do |backend|
            backend.pty                = pty
            backend.connection_timeout = connection_timeout
            backend.ssh_options        = 
              backend.ssh_options.merge(user: user).merge!(ssh_options)
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