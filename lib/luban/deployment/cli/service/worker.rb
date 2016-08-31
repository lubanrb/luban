module Luban
  module Deployment
    module Service
      class Worker < Luban::Deployment::Package::Worker
        module Base
          def shell_setup_commands
            @shell_setup_commands ||= ["source #{envrc_file}"]
          end

          def compose_command(cmd)
            "#{shell_setup_commands.join('; ')}; #{cmd} 2>&1"
          end
          
          %i(name full_name version major_version patch_level).each do |method|
            define_method("service_#{method}") { send("target_#{method}") }
          end

          def profile_name; service_name; end

          def service_entry
            @service_entry ||= "#{env_name.gsub('/', '.')}.#{profile_name}"
          end

          def profile_path
            @profile_path ||= shared_path.join('profile', profile_name)
          end

          def log_path
            @log_path ||= shared_path.join('log')
          end

          def log_file_path
            @log_file_path ||= log_path.join(log_file_name)
          end

          def log_file_name
            @log_file_name ||= "#{service_name}.log"
          end

          def pids_path
            @pids_path ||= shared_path.join('pids')
          end

          def pid_file_path
            @pid_file_path ||= pids_path.join(pid_file_name)
          end

          def pid_file_name
            @pid_file_name ||= "#{service_name}.pid"
          end

          def control_file_path
            @control_file_path ||= profile_path.join(control_file_name)
          end

          def control_file_name
            @control_file_name ||= "#{service_name}.conf"
          end

          def logrotate_file_path
            @logrotate_file_path ||= profile_path.join(logrotate_file_name)
          end

          def logrotate_file_name
            @logrotate_file_name ||= "#{service_name}.logrotate"
          end
        end

        include Base
      end
    end
  end
end
