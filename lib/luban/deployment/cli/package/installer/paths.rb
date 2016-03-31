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

        def src_file_path
          @src_file_path ||= tmp_path.join(src_file_name)
        end

        def source_repo
          raise NotImplementedError, "#{self.class.name}#source_repo is an abstract method."
        end

        def download_from_source?
          lubhub_repo.nil?
        end

        def download_from_lubhub?
          !lubhub_repo.nil?
        end

        def download_repo
          @download_repo ||= download_from_source? ? source_repo : lubhub_repo
        end

        def source_url_root
          raise NotImplementedError, "#{self.class.name}#source_url_root is an abstract method."
        end

        def download_url_root
          @download_url_root ||= download_from_source? ? source_url_root : package_name
        end

        def download_url
          @download_url ||= File.join(download_repo, download_url_root, src_file_name)
        end

        def install_path
          @install_path ||= package_path.join('versions', package_version)
        end

        def bin_path
          @bin_path ||= install_path.join('bin')
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