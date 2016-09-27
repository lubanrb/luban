module Luban
  module Deployment
    module Packages
      class Git < Luban::Deployment::Package::Base
        apply_to :all do
          before_install do
            depend_on 'openssl', version: '1.0.2h'
          end
        end

        protected

        def setup_provision_tasks
          super
          provision_tasks[:install].option :openssl, "OpenSSL version"
        end

        class Installer < Luban::Deployment::Package::Installer
          define_executable 'git'

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
