module Luban
  module Deployment
    module Helpers
      module LinkedPaths
        def linked_dirs; @linked_dirs ||= []; end
        def linked_files; @linked_files ||= []; end

        protected

        def init
          super
          linked_dirs.push('log', 'pids')
        end

        def assure_linked_dirs
          return if linked_dirs.empty?
          assure_dirs(linked_dirs.collect { |dir| shared_path.join(dir) })
        end

        def create_linked_dirs(dirs, from:, to:)
          dirs.each do |path|
            target_path = to.join(path)
            assure_dirs(target_path.dirname)
            rmdir(target_path) if directory?(target_path)
            source_path = from.join(path)
            assure_symlink(source_path, target_path) #if directory?(source_path)
          end
        end

        def create_linked_files(files, from:, to:)
          files.each do |path|
            target_path = to.join(path)
            assure_dirs(target_path.dirname)
            rm(target_path) if file?(target_path)
            source_path = from.join(path)
            assure_symlink(source_path, target_path) #if file?(source_path)
          end
        end
      end
    end
  end
end
