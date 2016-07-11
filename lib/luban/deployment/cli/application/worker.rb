module Luban
  module Deployment
    class Application
      class Worker < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote
        include Luban::Deployment::Service::Worker::Base

        %i(name full_name version major_version patch_level).each do |method|
          define_method("application_#{method}") { send("target_#{method}") }
        end

        def packages; task.opts.packages; end

        def package_version(package_name); packages[package_name.to_sym].current_version; end

        def package_path(package_name)
          @package_path ||= luban_install_path.join('pkg', package_name.to_s, 'versions', 
                                                    package_version(package_name))
        end

        def package_bin_path(package_name)
          @package_bin_path ||= package_path(package_name).join('bin')
        end

        def service_entry
          @service_entry ||= "#{env_name.gsub('/', '.')}.app"
        end
      end
    end
  end
end
