module Luban
  module Deployment
    module Parameters
      module Base
        def parameter(*params)
          params.each do |param|
            define_method(param) do |value = nil|
              value.nil? ? fetch(__method__) : set(__method__, value)
            end
          end
        end
      end

      module General
        extend Base

        DefaultLubanRootPath = Pathname.new('/opt/luban')

        def self.included(mod)
          mod.extend(Base)
        end

        parameter :luban_roles
        parameter :luban_root_path

        parameter :stages
        parameter :applications

        parameter :work_dir
        parameter :apps_path
        parameter :project
        parameter :user
        parameter :config_finder

        protected

        def set_default_general_parameters
          set_default :luban_roles, %i(app)
          set_default :luban_root_path, DefaultLubanRootPath
          set_default :user, ENV['USER']
          set_default :config_finder, {}
        end

        def validate_general_parameters
          if user != ENV['USER']
            abort "Aborted! Given deployment user (#{user.inspect}) is NOT the current user #{ENV['USER'].inspect}" +
                  "Please switch to the deployment user before any deployments."
          end
          if project.nil?
            abort "Aborted! Please specify the project name: project 'project name'"
          end
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

        parameter :process_monitor
        parameter :sshkit_backend
        parameter :authen_key_type
        parameter :default_env
        parameter :pty
        parameter :connection_timeout
        parameter :ssh_options
        parameter :use_sudo

        protected

        def set_default_project_parameters
          set_default :process_monitor, {}
          set_default :sshkit_backend, SSHKit::Backend::Netssh
          set_default :authen_key_type, 'rsa'
          set_default :default_env, { path: '$PATH:/usr/local/bin' }
          set_default :pty, false
          set_default :connection_timeout, 30 # second
          set_default :ssh_options, {}
          set_default :use_sudo, false # Turn off sudo by default

          setup_default_project_config_finder
        end

        def setup_default_project_config_finder
          config_finder[:project] ||=
            Luban::Deployment::Helpers::Configuration::Finder.project(self)
        end

        def validate_project_parameters
          unless process_monitor.empty?
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

        parameter :application
        parameter :scm_role
        parameter :keep_releases
        parameter :linked_dirs
        parameter :linked_files
        parameter :logrotate_files

        protected

        def set_default_application_parameters
          set_default :scm_role, :scm
          set_default :keep_releases, 3
          set_default :linked_dirs, []
          set_default :linked_files, []
          set_default :logrotate_files, []

          setup_default_application_config_finder
        end

        def setup_default_application_config_finder
          config_finder[:application] ||= 
            Luban::Deployment::Helpers::Configuration::Finder.application(self)
        end

        def validate_application_parameters
          if application.nil?
            abort "Aborted! Please specify the application name - application 'app name'"
          end
        end
      end
    end
  end
end
