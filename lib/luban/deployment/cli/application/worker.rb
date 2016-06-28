module Luban
  module Deployment
    class Application
      class Worker < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote
        include Luban::Deployment::Service::Worker::Base

        def service_name
          @service_name ||= task.opts.name
        end

        def service_version
          @service_version ||= task.opts.version
        end

        def service_full_name
          @service_full_name ||= "#{service_name}-#{service_version}"
        end
      end
    end
  end
end
