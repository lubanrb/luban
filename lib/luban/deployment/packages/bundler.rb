module Luban
  module Deployment
    module Packages
      class Bundler < Luban::Deployment::Package::Base
        protected

        def setup_install_tasks
          super
          commands[:install].switch :install_doc, "Install Bundler document"
        end

        class Installer < Luban::Deployment::Package::Installer
          def install_doc?
            task.opts.install_doc
          end

          def package_path
            parent.package_path
          end

          def install_path
            parent.install_path
          end

          define_executable 'bundler'

          def gem_executable
            parent.gem_executable
          end

          def src_file_extname
            @src_file_extname ||= 'gem'
          end

          def source_repo
            #@source_repo ||= "http://production.cf.rubygems.org"
            @source_repo ||= "https://rubygems.org"
          end

          def source_url_root
            @source_url_root ||= "downloads"
          end

          def installed?
            return false unless file?(bundler_executable)
            match?("#{bundler_executable} -v", package_version)
          end

          protected

          def validate
            if parent.nil?
              abort "Aborted! Parent package for Bundler MUST be provided."
            end
            unless parent.is_a?(Ruby::Installer)
              abort "Aborted! Parent package for Bundler MUST be an instance of #{Ruby::Installer.name}"
            end
          end

          def uncompress_package; end
          def configure_package; end
          def make_package; end
          def build_package; install_package; end
          def update_binstubs!; end

          def install_package!
            install_opts = ['--local']
            install_opts << "--no-document" unless install_doc?
            test("#{gem_executable} uninstall bundler -a -x -I >> #{install_log_file_path} 2>&1") and
            test("#{gem_executable} install #{install_opts.join(' ')} #{src_cache_path} >> #{install_log_file_path} 2>&1")
          end
        end
      end
    end
  end
end
