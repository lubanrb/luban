module Luban
  module Deployment
    module Service
      class Controller < Worker
        def pid
          capture(:cat, "#{pid_file_path} 2>/dev/null")
        end

        def process_started?
          !!process_grep.keys.first
        end

        def process_stopped?
          !process_started?
        end

        def pid_file_orphaned?
          process_stopped? and pid_file_exists?
        end

        def pid_file_missing?
          process_started? and !pid_file_exists?
        end

        def pid_file_exists?
          file?(pid_file_path, "-s") # file is NOT zero size
        end

        def process_pattern
          raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
        end

        def start_process
          if process_started?
            update_result "Skipped! Already started #{package_full_name}", status: :skipped
            return
          end

          output = start_process!
          if check_until { process_started? }
            monitor_process
            update_result "Start #{package_full_name}: [OK] #{output}"
          else
            remove_orphaned_pid_file
            update_result "Start #{package_full_name}: [FAILED] #{output}", 
                          status: :failed, level: :error
          end
        end

        def stop_process
          if process_stopped?
            update_result "Skipped! Already stopped #{package_full_name}", status: :skipped
            return
          end

          output = stop_process! || 'OK'
          if check_until { process_stopped? }
            unmonitor_process
            update_result "Stop #{package_full_name}: [OK] #{output}"
          else
            remove_orphaned_pid_file
            update_result "Stop #{package_full_name}: [FAILED] #{output}",
                          status: :failed, level: :error
          end
        end

        def restart_process
          if process_started?
            output = stop_process!
            if check_until { process_stopped? }
              info "Stop #{package_full_name}: [OK] #{output}"
              unmonitor_process
            else
              remove_orphaned_pid_file
              update_result "Stop #{package_full_name}: [FAILED] #{output}",
                            status: :failed, level: :error
              return
            end
          end

          output = start_process!
          if check_until { process_started? }
            update_result "Restart #{package_full_name}: [OK] #{output}"
            monitor_process
          else
            remove_orphaned_pid_file
            update_result "Restart #{package_full_name}: [FAILED] #{output}", 
                          status: :failed, level: :error
          end
        end

        def check_process
          update_result check_process!
        end

        def kill_process
          output = kill_process!
          if check_until { process_stopped? }
            unmonitor_process
            remove_orphaned_pid_file
            update_result "Kill #{package_full_name}: [OK] #{output}"
          else
            update_result "Kill #{package_full_name}: [FAILED] #{output}"
          end
        end

        def process_monitor_defined?
          !process_monitor[:name].nil?
        end

        def monitor_process
          if process_monitor_defined?
            if monitor_process!
              info "Turned on process monitor for #{service_entry}"
            else
              info "Failed to turn on process monitor for #{service_entry}"
            end
          end
        end

        def unmonitor_process
          if process_monitor_defined?
            if unmonitor_process!
              info "Turned off process monitor for #{service_entry}"
            else
              info "Failed to turn off process monitor for #{service_entry}"
            end
          end
        end

        protected

        %i(start_process! stop_process!).each do |m|
          define_method(m) do
            raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
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

        def check_process!
          if pid_file_missing?
            "#{package_full_name}: started but PID file does NOT exist - #{pid_file_path}"
          elsif process_started?
            "#{package_full_name}: started (PID #{pid})"
          elsif pid_file_orphaned?
            "#{package_full_name}: stopped but PID file exists - #{pid_file_path}"
          else
            "#{package_full_name}: stopped"
          end
        end

        def kill_process!(pattern = process_pattern)
          capture(:pkill, "-9 -f \"#{pattern}\"")
        end

        def process_grep(pattern = process_pattern)
          capture(:pgrep, "-l -f \"#{pattern}\" 2>/dev/null").split.inject({}) do |h, p|
            pid, pname = p.split(' ', 2)
            h[pid] = pname
            h
          end
        end

        def remove_orphaned_pid_file
          rm(pid_file_path) if pid_file_orphaned?
        end

        def monitor_process!
          test(process_monitor_command)
        end

        def unmonitor_process!
          test(process_unmonitor_command)
        end

        def process_monitor_executable
          @process_monitor_executable ||= env_path.join("#{stage}.#{process_monitor[:env]}").
                                                   join('bin').join(process_monitor[:name])
        end

        def process_monitor_command
          @process_monitor_command ||= "#{process_monitor_executable} monitor #{service_entry}"
        end

        def process_unmonitor_command
          @process_unmonitor_command ||= "#{process_monitor_executable} unmonitor #{service_entry}"
        end
      end
    end
  end
end
