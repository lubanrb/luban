module Luban
  module Deployment
    module Package
      class Installer
        DefaultSrcFileExtName = 'tar.gz'

        def src_file_name
          @src_file_name ||= "#{package_full_name}.#{src_file_extname}"
        end

        def src_file_extname
          @src_file_extname ||= DefaultSrcFileExtName
        end

        def src_cache_path
          @src_cache_path ||= tmp_path.join(src_file_name)
        end

        def src_file_path 
          @src_file_path ||= package_downloads_path.join(src_file_name)
        end

        def source_repo
          raise NotImplementedError, "#{self.class.name}#source_repo is an abstract method."
        end

        def source_url_root
          raise NotImplementedError, "#{self.class.name}#source_url_root is an abstract method."
        end

        def download_url
          @download_url ||= File.join(source_repo, source_url_root, src_file_name)
        end

        def lib_path
          @lib_path ||= install_path.join('lib')
        end

        def include_path
          @include_path ||= install_path.join('include')
        end

        def build_path
          @build_path ||= package_tmp_path.join(package_full_name)
        end

        def install_log_path
          @install_log_path ||= package_path.join('log').join(package_full_name)
        end

        def install_log_file_path
          @install_log_file_path ||= install_log_path.join(install_log_file_name)
        end

        def install_log_file_name
          @install_log_file_name ||= "#{package_full_name}-install-#{Time.now.strftime("%Y%m%d-%H%M%S")}.log"
        end
      end
    end
  end
end