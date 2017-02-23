require 'etc'

module Luban
  module Deployment
    module Parameters
      module Base
        def parameter(param, default: nil)
          define_method(param) do |value = nil|
            value.nil? ? fetch(__method__) : set(__method__, value)
          end
          define_method("set_default_for_#{param}") do
            if default.respond_to?(:call)
              set_default param, instance_exec(&default)
            else 
              set_default param, default
            end
          end
          protected "set_default_for_#{param}"
        end
      end

      module General
        extend Base

        DefaultLubanRootPath = Pathname.new('/opt/luban')

        def self.included(mod)
          mod.extend(Base)
        end

        def current_user
          ENV['USER'] || `whoami 2>/dev/null`.chomp
        end

        def current_uid
          Etc.getpwnam(current_user).uid
        end

        parameter :luban_roles, default: %i(app)
        parameter :luban_root_path, default: DefaultLubanRootPath

        parameter :stages
        parameter :applications
        parameter :env_vars, default: ->{ Hash.new }

        parameter :work_dir
        parameter :apps_path
        parameter :project
        parameter :user, default: ->{ current_user }
        parameter :author
        parameter :config_finder, default: ->{ Hash.new }

        parameter :skip_promptless_authen, default: false

        protected

        def validate_for_user
          if user.nil?
            abort "Abort! Please specify the user name: user 'user name'"
          end
          if user != current_user
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

      module Docker
        extend Base

        parameter :luban_uid, default: ->{ current_uid }
        parameter :luban_user, default: ->{ current_user }
        parameter :build_tag, default: '0.0.0'
        parameter :base_image, default: 'centos:7'
        parameter :timezone, default: 'UTC'
        parameter :base_packages, default: ->{ Array.new }
        parameter :docker_tls_verify, default: false
        parameter :docker_cert_path
        parameter :docker_tcp_port
        parameter :docker_unix_socket

        def has_base_packages?; !base_packages.empty?; end

        def validate_for_docker_cert_path
          return if !docker_tls_verify and docker_cert_path.nil?
          if docker_cert_path.is_a?(String)
            docker_cert_path Pathname.new(docker_cert_path)
          end
          unless docker_cert_path.is_a?(Pathname)
            abort "Aborted! Docker cert path should be a String or a Pathname: docker_cert_path 'path to docker certs'"
          end
        end
      end

      module Application
        extend Base
        include Docker

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

        def dockerize
          unless dockerized?
            singleton_class.send(:prepend, Luban::Deployment::Application::Dockerable)
            set :dockerized, true
            skip_promptless_authen true
          end
        end

        def dockerized?; fetch :dockerized; end

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
