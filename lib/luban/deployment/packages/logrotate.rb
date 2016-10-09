module Luban
  module Deployment
    module Packages
      class Logrotate < Luban::Deployment::Package::Base
        apply_to :all do
          before_install do
            depend_on 'popt', version: '1.16'
          end
        end

        class Installer < Luban::Deployment::Package::Installer
          define_executable 'logrotate'

          def source_repo
            @source_repo ||= "https://github.com"
          end

          def source_url_root
            @source_url_root ||= "logrotate/logrotate/releases/download/#{package_major_version}"
          end

          def installed?
            return false unless file?(logrotate_executable)
            pattern = "logrotate #{package_major_version}"
            match?("#{logrotate_executable} --version 2>&1", pattern)
          end

          def bin_path
            @bin_path ||= install_path.join('sbin')
          end

          protected

          def configure_package!
            with compose_build_env_variables do
              test("./autogen.sh", ">> #{install_log_file_path} 2>&1") and super
            end
          end
        end
      end
    end
  end
end
