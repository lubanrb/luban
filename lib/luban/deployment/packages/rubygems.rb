module Luban
  module Deployment
    module Packages
      class Rubygems < Luban::Deployment::Package::Base
        protected

        def setup_install_tasks
          super
          commands[:install].switch :install_doc, "Install Rubygems document"
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
          
          define_executable 'gem'
          
          def ruby_executable
            parent.ruby_executable
          end

          def src_file_extname
            @src_file_extname ||= 'tgz'
          end

          def source_repo
            #@source_repo ||= "http://production.cf.rubygems.org"
            @source_repo ||= "https://rubygems.org"
          end

          def source_url_root
            @source_url_root ||= "rubygems"
          end

          def installed?
            return false unless file?(gem_executable)
            match?("#{gem_executable} -v", package_version)
          end

          protected

          def configure_build_options
            super
            unless install_doc?
              @configure_opts.push('--no-rdoc', '--no-ri')
            end
          end

          def validate
            if parent.nil?
              abort "Aborted! Parent package for Rubygems MUST be provided."
            end
            unless parent.is_a?(Ruby::Installer)
              abort "Aborted! Parent package for Rubygems MUST be an instance of #{Ruby::Installer.name}"
            end
          end

          def configure_package!
            test(ruby_executable, 
                 "setup.rb config #{configure_opts.reject(&:empty?).join(' ')} >> #{install_log_file_path} 2>&1")
          end

          def make_package!
            test(ruby_executable, 
                 "setup.rb setup >> #{install_log_file_path} 2>&1")
          end

          def install_package!
            test(ruby_executable, 
                 "setup.rb install >> #{install_log_file_path} 2>&1")
          end

          def update_binstubs!; end
        end
      end
    end
  end
end
