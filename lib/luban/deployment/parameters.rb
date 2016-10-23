module Luban
  module Deployment
    module Parameters
      module Base
        def parameter(param, default: nil)
          define_method(param) do |value = nil|
            value.nil? ? fetch(__method__) : set(__method__, value)
          end
          define_method("set_default_for_#{param}") { set_default param, default }
          protected "set_default_for_#{param}"
        end
      end

      module General
        extend Base

        DefaultLubanRootPath = Pathname.new('/opt/luban')

        def self.included(mod)
          mod.extend(Base)
        end

        parameter :luban_roles, default: %i(app)
        parameter :luban_root_path, default: DefaultLubanRootPath

        parameter :stages
        parameter :applications
        parameter :env_vars, default: ->{ Hash.new }

        parameter :work_dir
        parameter :apps_path
        parameter :project
        parameter :user, default: ENV['USER']
        parameter :config_finder, default: ->{ Hash.new }

        protected

        def validate_for_user
          if user != ENV['USER']
            abort "Aborted! Given deployment user (#{user.inspect}) is NOT the current user #{ENV['USER'].inspect}" +
                  "Please switch to the deployment user before any deployments."
          end
        end

        def validate_for_project
          if project.nil?
            abort "Aborted! Please specify the project name: project 'project name'"
          end
        end

        def validate_for_luban_root_path
          if luban_root_path.is_a?(String)
            luban_root_path Pathname.new(luban_root_path)
          end
          unless luban_root_path.is_a?(Pathname)
            abort "Aborted! Luban root path should be a String or a Pathname: luban_root_path Pathname.new('#{DefaultLubanRootPath}')"
          end
        end
      end

      module Project
        extend Base

        parameter :stage

        parameter :process_monitor, default: ->{ Hash.new }
        parameter :sshkit_backend, default: SSHKit::Backend::Netssh
        parameter :authen_key_type, default: 'rsa'
        parameter :default_env, default: ->{ { path: '$PATH:/usr/local/bin' } }
        parameter :pty, default: false
        parameter :connection_timeout, default: 30 # second
        parameter :ssh_options, default: ->{ Hash.new }
        parameter :use_sudo, default: false # Turn off sudo by default

        def process_monitor_via(monitor, env: "uber/lubmon")
          monitor = monitor.to_s.downcase
          env = "#{stage}.#{env.to_s.downcase}"
          process_monitor name: monitor, env: env
        end

        def monitor_defined?; !process_monitor.empty?; end

        protected

        def set_default_for_project_config_finder
          config_finder[:project] ||=
            Luban::Deployment::Helpers::Configuration::Finder.project(self)
        end

        def validate_for_process_monitor
          if monitor_defined?
            if process_monitor[:name].nil?
              abort "Aborted! Please specify the process monitor."
            end
            if process_monitor[:env].nil?
              abort "Aborted! Please specify the process monitor environment."
            end
          end
        end
      end

      module Application
        extend Base

        DefaultLogrotateMaxAge = 7 # days
        DefaultLogrotateInterval = 10 # mins

        parameter :application
        parameter :scm_role, default: :scm
        parameter :archive_role, default: :archive
        parameter :logrotate_max_age, default: DefaultLogrotateMaxAge
        parameter :logrotate_interval, default: (ENV['LUBAN_LOGROTATE_INTERVAL'] || DefaultLogrotateInterval).to_i

        def env_name
          @env_name ||= "#{stage}.#{project}/#{application}"
        end

        def monitor_itself?
          env_name == process_monitor[:env]
        end

        def monitorable?
          monitor_defined? and !monitor_itself?
        end

        def logrotate_count
          logrotate_max_age * 24 * (60 / logrotate_interval)
        end

        protected

        def set_default_for_application_config_finder
          config_finder[:application] ||= 
            Luban::Deployment::Helpers::Configuration::Finder.application(self)
        end

        def validate_for_application
          if application.nil?
            abort "Aborted! Please specify the application name - application 'app name'"
          end
        end
      end
    end
  end
end
