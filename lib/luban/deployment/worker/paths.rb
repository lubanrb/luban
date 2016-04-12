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

          def tmp_path
            @tmp_path ||= luban_root_path.join('tmp')
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

          def luban_install_path
            @luban_install_path ||= project_path.join('.luban')
          end

          def envrc_file
            @envrc_file ||= app_path.join(".envrc")
          end

          def unset_envrc_file
            @unset_envrc_file ||= app_path.join(".unset_envrc")
          end
        end
      end
    end
  end
end