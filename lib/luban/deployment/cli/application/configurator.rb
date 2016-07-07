module Luban
  module Deployment
    class Application
      class Configurator < Worker
        include Luban::Deployment::Service::Configurator::Base

        def release_type; task.opts.release[:type]; end
        def release_tag; task.opts.release[:tag]; end

        def release_path
          @release_path ||= releases_path.join(release_type, release_tag)
        end
      end
    end
  end
end
