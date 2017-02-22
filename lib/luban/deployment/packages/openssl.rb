module Luban
  module Deployment
    module Packages
      class Openssl < Luban::Deployment::Package::Base
        def self.decompose_version(version)
          major_version, patch_level = version.split('-')
          if patch_level.nil?
            major_version = version[/^[0-9.]+/]
            patch_level = version[/[a-z]+$/]
          end
          { major_version: major_version, patch_level: patch_level }
        end

        protected

        def setup_provision_tasks
          super
          provision_tasks[:install].switch :install_doc, "Install OpenSSL document"
        end

        class Installer < Luban::Deployment::Package::Installer
          OSXArchArgs = {
            x86_64: %w(darwin64-x86_64-cc),
            i386:   %w(darwin-i386-cc)
          }

          def install_doc?
            task.opts.install_doc
          end

          def configure_executable
            @configure_executable = osx? ? './Configure' : './config'
          end

          define_executable 'openssl'

          def source_repo
            @source_repo ||= "ftp://ftp.openssl.org"
          end

          def source_url_root
            @source_url_root ||= "source"
          end

          def old_source_url_root
            @old_source_url_root ||= "source/old/#{package_major_version}"
          end

          def installed?
            return false unless file?(openssl_executable)
            match?("#{openssl_executable} version", package_version)
          end

          def default_configure_opts
            @default_configure_opts ||= %w(enable-ec_nistp_64_gcc_128 zlib-dynamic shared enable-cms)
          end

          protected

          def configure_build_options
            super
            @configure_opts.unshift(OSXArchArgs[hardware_name.to_sym]) if osx?
            if version_match?(package_major_version, ">=1.1.0")
              @configure_opts << "-Wl,-rpath -Wl,#{lib_path}"
              #@configure_opts << "-Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)'"
            else
              @configure_opts << "no-ssl2"
            end
          end

          def switch_source_url_root
            @source_url_root = old_source_url_root
            @download_url = nil
          end

          def validate_download_url!
            unless url_exists?(download_url)
              switch_source_url_root
              unless url_exists?(download_url)
                task.result.status = :failed
                task.result.message = "Package #{package_full_name} is NOT found from url: #{download_url}."
                raise InstallFailure, task.result.message
              end
            end
          end

          def make_package!
            (version_match?(package_major_version, ">=1.1.0") or 
             test(:make, :depend, ">> #{install_log_file_path} 2>&1")) and 
            super
          end

          def install_package!
            test(:make, install_doc? ? :install : :install_sw, ">> #{install_log_file_path} 2>&1")
          end
        end
      end
    end
  end
end
