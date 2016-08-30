module Luban
  module Deployment
    module Service
      class Installer < Luban::Deployment::Package::Installer
        include Worker::Base
        include Luban::Deployment::Helpers::LinkedPaths

        protected

        def bootstrap_install
          super
          assure_linked_dirs
        end

        def create_symlinks!
          super
          create_symlinks_for_linked_dirs
          create_symlinks_for_linked_files
        end

        def create_symlinks_for_linked_dirs
          create_linked_dirs(linked_dirs, from: shared_path, to: install_path)
        end

        def create_symlinks_for_linked_files
          create_linked_files(linked_files, from: profile_path, to: install_path.join('config'))
        end
      end
    end
  end
end
