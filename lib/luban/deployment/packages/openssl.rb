module Luban
  module Deployment
    module Packages
      class Openssl < Luban::Deployment::Package::Base
        class Installer < Luban::Deployment::Package::Installer
          OSXArchArgs = {
            x86_64: %w(darwin64-x86_64-cc enable-ec_nistp_64_gcc_128),
            i386:   %w(darwin-i386-cc)
          }

          def configure_executable
            @configure_executable = osx? ? './Configure' : './config'
            
          end

          default_executable 'openssl'

          def source_repo
            #@source_repo ||= "https://www.openssl.org"
            @source_repo ||= "http://www.openssl.org"
          end

          def source_url_root
            @source_url_root ||= "source"
          end

          def installed?
            return false unless file?(openssl_executable)
            match?("#{openssl_executable} version", package_version)
          end

          def default_configure_opts
            @default_configure_opts ||= %w(no-ssl2 zlib-dynamic shared enable-cms)
          end

          protected

          def configure_build_options
            super
            @configure_opts.unshift(OSXArchArgs[hardware_name.to_sym]) if osx?
          end

          def make_package!
            super and test(:make, "depend >> #{install_log_file_path} 2>&1")
          end

          def cleanup_temp!
            super
            # Clean up man pages
            manpages_path = install_path.join('ssl/man')
            rmdir(manpages_path) if directory?(manpages_path)
          end
        end
      end
    end
  end
end
