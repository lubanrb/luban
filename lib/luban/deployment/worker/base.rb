module Luban
  module Deployment
    module Worker
      class Base
        include Luban::Deployment::Helpers::Configuration
        include Luban::Deployment::Helpers::Utils
        include Luban::Deployment::Parameters::General
        include Luban::Deployment::Parameters::Project
        include Luban::Deployment::Parameters::Application

        attr_reader :task

        def initialize(config:, backend:, **task, &blk)
          @config = config
          @backend = backend
          @run_blk = blk
          @task = create_task(task)
          init
          validate
        end

        def force?; task.opts.force; end
        def dry_run?; task.opts.dry_run; end

        def osx?; os_name == 'Darwin'; end
        def linux?; os_name == 'Linux'; end

        def target_name; task.opts.name; end
        def target_full_name; "#{target_name}-#{target_version}"; end

        def target_version; task.opts.version; end
        def target_major_version; task.opts.major_version || target_version; end
        def target_patch_level; task.opts.patch_level || ''; end

        def packages; task.opts.packages; end

        def run
          with_clean_env do
            update_result(__return__: @run_blk ? run_with_block : run_with_command).to_h
          end
        end

        def method_missing(sym, *args, &blk)
          if args.empty? and blk.nil? and config.has_key?(sym)
            singleton_class.send(:define_method, sym) { config.fetch(__method__) }
            send(sym)
          else
            super
          end
        end

        protected

        def create_task(task)
          Task.new(task).tap { |t| t.result.hostname = hostname }
        end

        def init; end
        def validate; end
        def before_run; end
        def after_run; end

        def run_with_block
          before_run
          r = instance_eval &@run_blk
          after_run
          r
        end

        def run_with_command
          before_run
          send("before_#{task.cmd}") if respond_to?("before_#{task.cmd}", true)                    
          r = send(task.cmd)
          send("after_#{task.cmd}") if respond_to?("after_#{task.cmd}", true)
          after_run
          r
        end

        def update_result(message = nil, status: :succeeded, level: :info, **attrs)
          task.result.tap do |r|
            r.status = status unless status.nil? or !r.status.nil?
            r.level = level unless level.nil? or !r.level.nil?
            r.message = message unless message.nil? or !r.message.nil?
            attrs.each_pair { |k, v| r.send("#{k}=", v) }
            unless message.nil? or message.empty?
              message.split("\n").each { |msg| send(level, msg) }
            end
          end
        end
      end
    end
  end
end
