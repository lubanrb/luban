module Luban
  module Deployment
    module Packages
      class Git < Luban::Deployment::Package::Base
        apply_to :all do
          before_install do
            depend_on 'openssl', version: '1.0.2l'
            depend_on 'curl', version: '7.54.1'
          end
        end

        protected

        def setup_provision_tasks
          super
          provision_tasks[:install].switch :install_tcltk, "Install with TclTk"
          provision_tasks[:install].option :openssl, "OpenSSL version"
          provision_tasks[:install].option :curl, "Curl version"
        end

        class Installer < Luban::Deployment::Package::Installer
          def install_tcltk?
            task.opts.install_tcltk
          end

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

          def with_curl_dir(dir)
            @configure_opts << "--with-curl=#{dir}"
          end

          protected

          def configure_build_options
            super
            @configure_opts << "--without-tcltk" unless install_tcltk?
          end

          def make_package!
            test(:make, "NO_GETTEXT=1 >> #{install_log_file_path} 2>&1")
          end

          def install_package!
            test(:make, "NO_GETTEXT=1 install >> #{install_log_file_path} 2>&1")
          end
        end
      end
    end
  end
end
