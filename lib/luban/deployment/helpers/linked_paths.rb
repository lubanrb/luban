module Luban
  module Deployment
    module Helpers
      module LinkedPaths
        def linked_dirs; @linked_dirs ||= []; end
        def linked_files; @linked_files ||= []; end

        def linked_files_dir
          @linked_files_dir ||= 'config'
        end

        def linked_files_root
          @linked_files_root ||= config_finder[:application].stage_profile_path.join(profile_name)
        end

        def linked_files_from
          @linked_files_from ||= linked_files_root.join(linked_files_dir)
        end

        protected

        def init
          super
          init_linked_dirs
          init_linked_files
        end

        def init_linked_dirs
          linked_dirs.push('log', 'pids')
        end

        def init_linked_files
          return unless linked_files_from.directory?
          Dir.chdir(linked_files_from) do
            linked_files.concat(Pathname.glob("**/*").select { |f| f.file? })
          end
        end

        def assure_linked_dirs
          return if linked_dirs.empty?
          assure_dirs(linked_dirs.collect { |dir| shared_path.join(dir) })
        end

        def create_linked_dirs(dirs = linked_dirs, from: shared_path, to:)
          dirs.each do |path|
            target_path = to.join(path)
            assure_dirs(target_path.dirname)
            rmdir(target_path) if directory?(target_path)
            source_path = from.join(path)
            assure_symlink(source_path, target_path) 
          end
        end

        def create_linked_files(files = linked_files, from: profile_path, to:)
          files.each do |path|
            target_path = to.join(linked_files_dir, path)
            assure_dirs(target_path.dirname)
            rm(target_path) if file?(target_path)
            source_path = from.join(linked_files_dir, path)
            assure_symlink(source_path, target_path)
          end
        end

        def create_symlinks_for_archived_logs
          assure_symlink(archived_logs_path, log_path.join(archived_logs_path.basename))
        end
      end
    end
  end
end
