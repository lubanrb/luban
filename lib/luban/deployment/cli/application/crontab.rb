module Luban
  module Deployment
    class Application
      class Crontab < Worker
        def cronjobs; backend.host.cronjobs; end
        def has_cronjobs?; !cronjobs.empty?; end

        def crontab_file_path
          @crontab_file_path ||= shared_path.join(crontab_file_name)
        end

        def tmp_crontab_file_path
          @tmp_crontab_file_path ||= shared_path.join(".tmp.#{crontab_file_name}")
        end

        def crontab_file_name
          @crontab_file_name ||= "crontab"
        end

        def crontab_template_file
          @crontab_template_file ||= find_template_file("crontab.erb")
        end

        def crontab_header_template_file
          @crontab_header_template_file ||= find_template_file("crontab_header.erb")
        end

        def crontab_footer_template_file
          @crontab_footer_template_file ||= find_template_file("crontab_footer.erb")
        end

        def crontab_open
          @crontab_open ||= "# CRONTAB BEGIN : #{env_name}"
        end

        def crontab_close
          @crontab_close ||= "# CRONTAB END : #{env_name}"
        end

        def updated?
          extract_crontab == capture(:cat, crontab_file_path, "2>/dev/null")
        end

        def deploy_cronjobs
          if deploy_cronjobs!
            update_result "Successfully published #{crontab_file_name}."
          else
            update_result "Skipped! ALREADY published #{crontab_file_name}.", status: :skipped
          end
        end

        def update_cronjobs
          unless file?(crontab_file_path)
            update_result "FAILED to update crontab: missing #{crontab_file_path}.", status: :failed, level: :error
            return
          end
          if updated?
            update_result "Skipped! ALREADY updated crontab.", status: :skipped
            return
          end

          update_cronjobs!
          if updated?
            update_result "Successfully updated crontab."
          else
            update_result "FAILED to update crontab.", status: :failed, level: :error
          end
        end

        def list_cronjobs
          crontab = extract_crontab(task.opts.all)
          if crontab.empty?
            update_result "No crontab for #{user}."
          else
            update_result crontab
          end
        end

        def shell_setup
          @shell_setup ||= task.opts.release.nil? ? ["source #{envrc_file}"] : super
        end

        def shell_delimiter; @shell_delimiter ||= '&&'; end

        protected

        def deploy_cronjobs!
          rm(crontab_file_path) if force?
          upload_by_template(file_to_upload: crontab_file_path,
                             template_file:  crontab_template_file,
                             header_file: crontab_header_template_file,
                             footer_file: crontab_footer_template_file,
                             auto_revision: true)
        end

        def crontab_entry(command:, schedule:, output: "", type: :shell, disabled: false)
          if output.is_a?(String) and !output.empty?
            output = log_path.join("cron.#{output}")
          end
          command_composer = "#{type}_command"
          unless respond_to?(command_composer)
            abort "Aborted! Unknown cronjob type: #{type.inspect}"
          end
          command = send(command_composer, command, output: output)
          entry = "#{schedule} #{command}"
          disabled ? "# DISABLED - #{entry}" : entry
        end

        def update_cronjobs!
          crontab = capture(:crontab, "-l")
          new_crontab = capture(:cat, crontab_file_path, "2>/dev/null")
          old = false
          crontab = crontab.split("\n").inject([]) do |lines, line|
            if old || line == crontab_open
              lines << new_crontab unless (old = line != crontab_close)
            else
              lines << line
            end
            lines
          end
          if crontab.empty?
            test(:crontab, crontab_file_path, "2>&1")
          else
            upload!(StringIO.new(crontab.join("\n")), tmp_crontab_file_path)
            test(:crontab, tmp_crontab_file_path, "2>&1")
          end
        ensure
          rm(tmp_crontab_file_path)
        end

        def extract_crontab(all = false)
          crontab = capture(:crontab, "-l")
          return crontab if all

          old = false
          crontab.split("\n").inject([]) do |lines, line|
            if old || line == crontab_open
              lines << line
              old = line != crontab_close
            end
            lines
          end.join("\n")
        end
      end
    end
  end
end
