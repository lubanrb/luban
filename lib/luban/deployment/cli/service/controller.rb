module Luban
  module Deployment
    module Service
      class Controller < Worker
        module Base
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

          %i(process_pattern start_command stop_command).each do |m|
            define_method(m) do
              raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
            end
          end

          def monitor_executable
            @monitor_executable ||= env_path.join("#{stage}.#{process_monitor[:env]}", 'bin', process_monitor[:name])
          end

          def monitor_command
            @monitor_command ||= shell_command("#{monitor_executable} monitor #{service_entry}")
          end

          def unmonitor_command
            @unmonitor_command ||= shell_command("#{monitor_executable} unmonitor #{service_entry}")
          end

          def reload_monitor_command
            @reload_monitor_command ||= shell_command("#{monitor_executable} reload")
          end

          def start_process
            if process_started?
              update_result "Skipped! Already started #{service_full_name}", status: :skipped
              return
            end

            output = start_process!
            if check_until { process_started? }
              update_result "Start #{service_full_name}: [OK] #{output}"
              monitor_process
            else
              remove_orphaned_pid_file
              update_result "Start #{service_full_name}: [FAILED] #{output}", 
                            status: :failed, level: :error
            end
          end

          def stop_process
            if process_stopped?
              update_result "Skipped! Already stopped #{service_full_name}", status: :skipped
              return
            end

            unmonitor_process
            output = stop_process! || 'OK'
            if check_until { process_stopped? }
              update_result "Stop #{service_full_name}: [OK] #{output}"
            else
              update_result "Stop #{service_full_name}: [FAILED] #{output}",
                            status: :failed, level: :error
            end
            remove_orphaned_pid_file
          end

          def restart_process
            if process_started?
              unmonitor_process
              output = stop_process!
              if check_until { process_stopped? }
                remove_orphaned_pid_file
                info "Stop #{service_full_name}: [OK] #{output}"
              else
                remove_orphaned_pid_file
                update_result "Stop #{service_full_name}: [FAILED] #{output}",
                              status: :failed, level: :error
                return
              end
            end

            output = start_process!
            if check_until { process_started? }
              update_result "Restart #{service_full_name}: [OK] #{output}"
              monitor_process
            else
              remove_orphaned_pid_file
              update_result "Restart #{service_full_name}: [FAILED] #{output}", 
                            status: :failed, level: :error
            end
          end

          def check_process
            update_result check_process!
          end

          def show_process
            update_result show_process!
          end

          def kill_process
            if process_stopped?
              update_result "Skipped! Already stopped #{service_full_name}", status: :skipped
              return
            end

            unmonitor_process
            output = kill_process!
            if check_until { process_stopped? }
              update_result "Kill #{service_full_name}: [OK] #{output}"
            else
              update_result "Kill #{service_full_name}: [FAILED] #{output}"
            end
            remove_orphaned_pid_file
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

          def reload_monitor_process
            if process_monitor_defined?
              if reload_monitor_process!
                info "Reloaded process monitor for #{service_entry}"
              else
                info "Failed to reload process monitor for #{service_entry}"
              end
            end
          end

          def default_pending_seconds; 30; end
          def default_pending_interval; 1; end

          protected

          def before_start_process
            reload_monitor_process
          end

          def check_until(pending_seconds: default_pending_seconds, 
                          pending_interval: default_pending_interval)
            succeeded = false
            (pending_seconds/pending_interval).times do
              sleep pending_interval
              break if (succeeded = yield)
            end
            succeeded
          end

          def start_process!; capture(start_command); end
          def stop_process!; capture(stop_command); end

          def check_process!
            if pid_file_missing?
              "#{service_full_name}: started but PID file(s) do NOT exist in #{pids_path}"
            elsif process_started?
              "#{service_full_name}: started - PID(s) #{pid}"
            elsif pid_file_orphaned?
              "#{service_full_name}: stopped but PID file(s) exist in #{pids_path}"
            else
              "#{service_full_name}: stopped"
            end
          end

          def kill_process!(pattern = process_pattern)
            capture(:pkill, "-9 -f \"#{pattern}\"")
          end

          def process_grep(pattern = process_pattern)
            capture(:pgrep, "-l -f -a \"#{pattern}\" 2>/dev/null").split("\n").inject({}) do |h, p|
              pid, pname = p.split(' ', 2)
              h[pid] = pname
              h
            end
          end

          def show_process!
            result = process_grep.inject("") do |s, (pid, cmd)|
                       s += "#{pid} : #{cmd}\n"
                     end
            result.empty? ? "No processes are found up and running." : result
          end

          def remove_orphaned_pid_file
            rm(pid_file_path) if pid_file_orphaned?
          end

          def monitor_process!
            test(monitor_command)
          end

          def unmonitor_process!
            test(unmonitor_command)
          end

          def reload_monitor_process!
            test(reload_monitor_command)
          end
        end
        
        include Base
      end
    end
  end
end
