module Luban
  module Deployment
    module Helpers
      module Configuration
        attr_accessor :config

        def config
          @config ||= Luban::Deployment::Configuration.new
        end

        def fetch(key, *args, &blk)
          config.fetch(key, *args, &blk)
        end

        def set(key, *args, &blk)
          config.set(key, *args, &blk)
        end

        def set_default(key, *args, &blk)
          config.set_default(key, *args, &blk)
        end

        def ask(key=nil, default: nil, prompt: nil, echo: true)
          config.ask(key, default: default, echo: echo, prompt: prompt)
        end

        def role(name, hosts, **properties)
          config.role(name, hosts, properties)
        end

        def server(name, **properties)
          config.server(name, properties)
        end

        def roles(*names)
          config.roles(*names)
        end

        def release_roles(*names)
          config.release_roles(*names)
        end

        def primary(role)
          config.primary(role)
        end

        def load_configuration_file(config_file, optional: false)
          if File.file?(config_file)
            if error = syntax_error?(config_file)
              abort "Aborted! Syntax errors in configuration file.\n#{error}"
            else
              instance_eval(File.read(config_file))
            end
          else
            unless optional
              abort "Aborted! Configuration file is NOT found: #{config_file}"
            end
          end
        end

        def syntax_error?(file)
          _stderr = $stderr
          $stderr = StringIO.new('', 'w')
          # ONLY work for MRI Ruby
          RubyVM::InstructionSequence.compile_file(file)
          $stderr.string.chomp.empty? ? false : $stderr.string
        ensure
          $stderr = _stderr
        end

        def find_template_file(file_name)
          path = find_template_file_by_config_finder(file_name) ||
                 find_default_template_file(file_name)
          raise RuntimeError, "Template file is NOT found: #{file_name}." if path.nil?
          path
        end

        protected

        def find_template_file_by_config_finder(file_name)
          path = config_finder[:application].find_template_file(file_name) ||
                 config_finder[:project].find_template_file(file_name)
        end

        def find_default_template_file(file_name)
          path = File.expand_path(File.join(File.dirname(__FILE__), '..', 
                                            'templates', file_name))
          return path if File.file?(path)
        end

        class Finder
          class Project < Finder
            def base_path; base_path ||= target.work_dir; end
          end

          class Application < Finder
            def base_path; base_path ||= target.apps_path.join(target.application); end
          end

          def self.project(target); Project.new(target); end
          def self.application(target); Application.new(target); end

          attr_reader :target
          attr_reader :base_path
          attr_reader :config_root
          attr_reader :config_file
          attr_reader :config_path
          attr_reader :templates_path
          attr_reader :stage_config_file
          attr_reader :stage_config_path
          attr_reader :stage_templates_path

          def initialize(target)
            @target = target
            set_config_paths
          end

          def deployfile; @deployfile ||= 'deploy.rb';   end
          def stagefile;  @stagefile  ||= "#{target.stage}.rb"; end

          def load_configuration
            load_general_configuration
            load_stage_configuration
          end

          def load_general_configuration
            target.load_configuration_file(config_file)
          end

          def load_stage_configuration
            target.load_configuration_file(stage_config_file)
            if File.directory?(stage_config_path)
              Dir[stage_config_path.join("{packages}/**/*.rb")].each do |file|
                target.load_configuration_file(file)
              end
            end
          end

          def find_template_file(file_name)
            return file_path if File.file?(file_path = stage_templates_path.join(file_name))
            return file_path if File.file?(file_path = templates_path.join(file_name))
          end

          protected

          def set_config_paths
            @config_root = base_path.join('config')
            @config_file = @config_root.join(deployfile)
            @config_path = @config_root.join(deployfile.sub('.rb', ''))
            @templates_path = @config_root.join('templates')
            @stage_config_file = @config_path.join(stagefile)
            @stage_config_path = @config_path.join(target.stage)
            @stage_templates_path = @stage_config_path.join('templates')
          end
        end
      end
    end
  end
end
