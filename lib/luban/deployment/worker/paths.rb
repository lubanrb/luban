module Luban
  module Deployment
    module Worker
      module Paths
        module Local
          def project_path
            @project_path ||= work_dir
          end

          def apps_path
            @apps_path ||= project_path.join('apps')
          end

          def app_path
            @app_path ||= apps_path.join(application)
          end
        end

        module Remote
          def env_path
            @env_path ||= luban_root_path.join('env')
          end

          def etc_path
            @etc_path ||= luban_root_path.join('etc')
          end

          def logrotate_path
            @logrotate_path = etc_path.join('logrotate')
          end

          def tmp_path
            @tmp_path ||= luban_root_path.join('tmp')
          end

          def downloads_path
            @downloads_path ||= luban_root_path.join('downloads')
          end

          def project_path
            @project_path ||= env_path.join("#{stage}.#{project}")
          end

          def app_path
            @app_path ||= project_path.join(application)
          end

          def app_bin_path
            @app_bin_path ||= app_path.join('bin')
          end

          def app_tmp_path
            @app_tmp_path ||= app_path.join('tmp')
          end

          def releases_path
            @releases_path ||= app_path.join('releases')
          end

          def shared_path
            @shared_path ||= app_path.join('shared')
          end

          def envrc_file
            @envrc_file ||= app_path.join(".envrc")
          end

          def unset_envrc_file
            @unset_envrc_file ||= app_path.join(".unset_envrc")
          end

          def luban_install_path
            @luban_install_path ||= project_path.join('.luban')
          end

          module Service
            def profile_path
              @profile_path ||= shared_path.join('profile')
            end

            def log_path
              @log_path ||= shared_path.join('log')
            end

            def log_file_path
              @log_file_path ||= log_path.join(log_file_name)
            end

            def log_file_name
              raise NotImplementedError, "#{self.class.name}#log_file_name is an abstract method."
            end

            def pids_path
              @pids_path ||= shared_path.join('pids')
            end

            def pid_file_path
              @pid_file_path ||= pids_path.join(pid_file_name)
            end

            def pid_file_name
              raise NotImplementedError, "#{self.class.name}#pid_file_name is an abstract method."
            end

            def control_file_path
              @control_file_path ||= profile_path.join(control_file_name)
            end

            def control_file_name
              raise NotImplementedError, "#{self.class.name}#control_file_name is an abstract method."
            end

            def logrotate_file_path
              @logrotate_file_path ||= profile_path.join(logrotate_file_name)
            end

            def logrotate_file_name
              raise NotImplementedError, "#{self.class.name}#logrotate_file_name is an abstract method."
            end
          end
        end
      end
    end
  end
end