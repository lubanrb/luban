module Luban
  module Deployment
    module Package
      class Worker < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote

        class << self
          def package_class(package)
            Luban::Deployment::Package::Base.package_class(package)
          end

          def worker_class(worker, **opts)
            Luban::Deployment::Package::Base.worker_class(worker, **opts)
          end

          def define_executable(*names)
            names.each do |name|
              define_method("#{name.gsub('-', '_')}_executable") do
                if instance_variable_defined?("@#{__method__}")
                  instance_variable_get("@#{__method__}")
                else
                  instance_variable_set("@#{__method__}", bin_path.join(name))
                end
              end
            end
          end
        end

        %i(name full_name version major_version patch_level).each do |method|
          define_method("package_#{method}") { send("target_#{method}") }
        end

        def parent; task.opts.parent; end
        def child?; !parent.nil?; end     

        def current_path
          @current_path ||= app_path.join(package_name)
        end

        def current_bin_path
          @current_bin_path ||= current_path.join('bin')
        end

        def package_path
          @package_path ||= luban_install_path.join('pkg', package_name)
        end

        def package_versions_path
          @package_versions_path ||= package_path.join('versions')
        end

        def install_path
          @install_path ||= package_versions_path.join(package_version)
        end

        def bin_path
          @bin_path ||= install_path.join('bin')
        end

        def package_tmp_path
          @package_tmp_path ||= package_path.join('tmp')
        end

        def package_downloads_path
          @package_downloads_path ||= downloads_path.join(package_name)
        end
      end
    end
  end
end
