module Luban
  module Deployment
    module Packages
      class Git < Luban::Deployment::Package::Binary
        apply_to :all do
          before_install do
            depend_on 'openssl', version: '1.0.2g'
          end
        end

        class Installer < Luban::Deployment::Package::Installer
          def git_executable
            @git_executable ||= bin_path.join('git')
          end

          def source_repo
            @source_repo ||= "https://www.kernel.org"
          end

          def source_url_root
            @source_url_root ||= "pub/software/scm/git"
          end

          def installed?
            return false unless file?(git_executable)
            pattern = "version #{package_major_version}"
            match?("#{git_executable} --version", pattern)
          end

          def with_openssl_dir(dir)
            @configure_opts << "--with-openssl=#{dir}"
          end
        end
      end
    end
  end
end
