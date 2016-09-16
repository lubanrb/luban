module Luban
  module Deployment
    class Application
      class Worker < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote
        include Luban::Deployment::Service::Worker::Base

        def gemfile
          @gemfile ||= release_path.join('Gemfile')
        end

        def has_gemfile?; file?(gemfile); end

        def shell_setup_commands
          @shell_setup_commands ||= super << "cd #{release_path}"
        end

        %i(name full_name version major_version patch_level).each do |method|
          define_method("application_#{method}") { send("target_#{method}") }
        end

        def profile_name; 'app'; end

        def release_tag; task.opts.release[:tag]; end

        def releases_path
          @releases_path ||= super.join('app')
        end

        def release_path
          @release_path ||= releases_path.join(release_tag)
        end

        def ruby_bin_path
          @ruby_bin_path ||= package_bin_path('ruby')
        end

        def bundle_executable
          @bundle_executable ||= ruby_bin_path.join('bundle')
        end

        def bundle_exec(cmd, **opts)
          compose_command("#{bundle_executable} exec #{cmd}", **opts)
        end
      end
    end
  end
end
