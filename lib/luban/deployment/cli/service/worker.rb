module Luban
  module Deployment
    module Service
      module Paths
        include Luban::Deployment::Worker::Paths::Remote::Service

        def service_name
          @service_name = package_name.downcase
        end

        def profile_path
          @profile_path ||= super.join(service_name)
        end

        def control_file_name
          @control_file_name ||= "#{service_name}.conf"
        end

        def logrotate_file_name
          @logrotate_file_name ||= "#{service_name}.logrotate"
        end

        def pid_file_name
          @pid_file_name ||= "#{service_name}.pid"
        end

        def log_file_name
          @log_file_name ||= "#{service_name}.log"
        end
      end

      class Worker < Luban::Deployment::Package::Worker
        include Paths
      end
    end
  end
end