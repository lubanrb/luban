module Luban
  module Deployment
    class Application
      class Constructor < Worker
        def envrc_template_file
          @envrc_template_file ||= find_template_file("envrc.erb")
        end

        def unset_envrc_template_file
          @unset_envrc_template_file ||= find_template_file("unset_envrc.erb")
        end

        def setup
          bootstrap
          create_envrc_files
          update_result "Application environment is setup successfully."
        end

        def destroy
          task.opts.destroy_project ? destroy_project : destroy_app
        end

        def destroy_project
          rmdir(project_path)
          update_result "The project environment is destroyed."
        end

        def destroy_app
          rmdir(app_path)
          update_result "The application environment is destroyed."
        end

        def cleanup
          execute("find #{tmp_path}/* -type f|xargs rm -f")
          update_result "Temporary files in app environment is cleaned up."
        end

        protected

        def bootstrap
          assure_dirs(downloads_path, archived_logs_path, 
                      tmp_path, app_bin_path, app_tmp_path, 
                      releases_path, packages_path, shared_path)
        end

        def create_envrc_files
          upload_by_template(file_to_upload: envrc_file,
                             template_file:  envrc_template_file,
                             auto_revision: true)
          upload_by_template(file_to_upload: unset_envrc_file,
                             template_file:  unset_envrc_template_file,
                             auto_revision: true)
        end
      end
    end
  end
end
