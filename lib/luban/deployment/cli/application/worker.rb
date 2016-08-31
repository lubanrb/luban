module Luban
  module Deployment
    class Application
      class Worker < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote
        include Luban::Deployment::Service::Worker::Base

        def shell_setup_commands
          super << "cd #{release_path}"
        end

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

        def profile_name; 'app'; end

        def release_tag; task.opts.release[:tag]; end

        def releases_path
          @releases_path ||= super.join('app')
        end

        def release_path
          @release_path ||= releases_path.join(release_tag)
        end
      end
    end
  end
end
