module Luban
  module Deployment
    module Service
      class Controller < Worker
        %i(process_stopped? process_started?
           monitor_process unmonitor_process).each do |m|
          define_method(m) do
            raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
          end
        end

        def start_process
          if process_started?
            update_result "Skipped! Already started #{package_full_name}", status: :skipped
            return
          end

          output = start_process!
          if check_until { process_started? }
            update_result "Successfully started #{package_full_name}: #{output}"
          else
            update_result "Failed to start #{package_full_name}: #{output}", 
                          status: :failed, level: :error
          end
        end

        def stop_process
          if process_stopped?
            update_result "Skipped! Already stopped #{package_full_name}", status: :skipped
            return
          end

          output = stop_process!
          if check_until { process_stopped? }
            update_result "Successfully stopped #{package_full_name}: #{output}"
          else
            update_result "Failed to stop #{package_full_name}: #{output}",
                          status: :failed, level: :error
          end
        end

        def restart_process
          if process_started?
            output = stop_process!
            unless check_until { process_stopped? }
              update_result "Failed to stop #{package_full_name}: #{output}",
                            status: :failed, level: :error
              return
            end
          end

          output = start_process!
          if check_until { process_started? }
            update_result "Successfully restarted #{package_full_name}: #{output}"
          else
            update_result "Failed to restart #{package_full_name}: #{output}", 
                          status: :failed, level: :error
          end
        end

        def check_process
          update_result check_process!
        end

        def kill_process
          output = kill_process!
          if check_until { process_stopped? }
            update_result "Successfully kill processs (#{output})."
          else
            update_result "Failed to kill process: #{output}"
          end
        end

        def check_until(pending_seconds = 30)
          succeeded = false
          pending_seconds.times do
            sleep 1
            break if (succeeded = yield)
          end
          succeeded
        end

        protected

        %i(start_process! stop_process! check_process!).each do |m|
          define_method(m) do
            raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
          end
        end

        def kill_process!
          pid = capture(pid_file_path)
          output = capture(:kill, "-9 #{pid}")
          output.empty? ? pid : output
        end
      end
    end
  end
end
