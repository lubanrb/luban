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

          def default_executable(name)
            define_method("#{name}_executable") do
              @default_executable ||= bin_path.join(name)
            end
          end
        end

        def package_name; task.opts.name; end
        def package_full_name; "#{package_name}-#{package_version}"; end

        def package_version; task.opts.version; end
        def package_major_version; task.opts.major_version; end
        def package_patch_level; task.opts.patch_level; end

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
