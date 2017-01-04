module Luban
  module Deployment
    module Packages
      class Gem < Luban::Deployment::Package::Base        
        class << self
          using Luban::CLI::CoreRefinements

          def gem_name
            @gem_name ||= name.split('::').last.snakecase.gsub('_', '-')
          end

          protected

          def get_latest_version
            require 'json'
            JSON.parse(`curl https://rubygems.org/api/v1/versions/#{gem_name}/latest.json 2>/dev/null`)['version']
          end
        end

        protected

        def setup_provision_tasks
          super
          provision_tasks[:install].switch :install_doc, "Install #{self.class.gem_name} document"
        end

        class Installer < Luban::Deployment::Package::Installer
          def install_doc?; task.opts.install_doc; end
          def package_path; parent.package_path; end
          def install_path; parent.install_path; end
          def gem_executable; parent.gem_executable; end
          def src_file_extname; @src_file_extname ||= 'gem'; end
          def source_repo; @source_repo ||= "https://rubygems.org"; end
          def source_url_root; @source_url_root ||= "downloads"; end

          protected

          def validate
            if parent.nil?
              abort "Aborted! Parent package for #{package_name} MUST be provided."
            end
            unless parent.is_a?(Ruby::Installer)
              abort "Aborted! Parent package for #{package_name} MUST be an instance of #{Ruby::Installer.name}"
            end
          end

          def uncompress_package; end
          def configure_package; end
          def make_package; end
          def build_package; install_gem!; end
          def update_binstubs; end

          def install_opts
            install_opts = ['--local']
            #install_opts << "--no-document" unless install_doc?
            install_opts << "--no-rdoc --no-ri" unless install_doc?
            install_opts
          end

          def install_gem!
            with_clean_env do
              test("#{gem_executable} install #{install_opts.join(' ')} #{src_cache_path} >> #{install_log_file_path} 2>&1")
            end
          end

          def uninstall_gem!
            with_clean_env do
              test("#{gem_executable} uninstall #{package_name} -a -x -I >> #{install_log_file_path} 2>&1")
            end
          end
        end
      end
    end
  end
end
