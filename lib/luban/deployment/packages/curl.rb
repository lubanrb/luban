module Luban
  module Deployment
    module Packages
      class Curl < Luban::Deployment::Package::Base
        apply_to :all do
          before_install do
            depend_on 'openssl', version: '1.0.2j'
          end
        end

        class Installer < Luban::Deployment::Package::Installer
          define_executable 'curl'

          def source_repo
            @source_repo ||= "https://curl.haxx.se"
          end

          def source_url_root
            @source_url_root ||= "download"
          end

          def installed?
            return false unless file?(curl_executable)
            pattern = "curl #{package_version}"
            match?("#{curl_executable} -V 2>&1", pattern)
          end

          def with_openssl_dir(dir)
            if osx? 
              @configure_opts << "--with-darwinssl"
            else
              @configure_opts << "--with-ssl=\"#{dir} -Wl,-rpath -Wl,#{dir.join('lib')}\""
            end
          end
        end
      end
    end
  end
end
