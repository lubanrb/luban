module Luban
  module Deployment
    class Application
      class Constructor < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote

        def envrc_template_file
          @envrc_template_file ||= find_template_file("envrc.erb")
        end

        def unset_envrc_template_file
          @unset_envrc_template_file ||= find_template_file("unset_envrc.erb")
        end

        def setup
          bootstrap
          create_envrc_files
        end

        def destroy
          task.opts.destroy_project ? destroy_project : destroy_app
        end

        def destroy_project
          rm(etc_path.join('*', "#{stage}.#{project}.*"))
          rmdir(project_path)
          update_result "The project environment is destroyed."
        end

        def destroy_app
          rm(etc_path.join('*', "#{stage}.#{project}.#{application}.*"))
          rmdir(app_path)
          update_result "The application environment is destroyed."
        end

        def cleanup
          execute("find #{tmp_path}/* -type f|xargs rm -f")
          update_result "Temporary files in app environment is cleaned up."
        end

        protected

        def bootstrap
          assure_dirs(logrotate_path, downloads_path,
                      tmp_path, app_bin_path, app_tmp_path, 
                      releases_path, shared_path)
          assure_linked_dirs
        end

        def assure_linked_dirs
          return if linked_dirs.empty?
          linked_dirs.each do |dir|
            linked_dir = shared_path.join(dir)
            assure(:directory, linked_dir) { mkdir(linked_dir) }
          end
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
