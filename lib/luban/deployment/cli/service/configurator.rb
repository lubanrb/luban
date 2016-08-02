module Luban
  module Deployment
    module Service
      class Configurator < Worker
        module Base
          def stage_profile_path
            @stage_profile_path ||= 
              config_finder[:application].stage_profile_path.join(service_name)
          end

          def profile_templates_path
            @profile_templates_path ||= 
              config_finder[:application].profile_templates_path.join(service_name)
          end

          def stage_profile_templates_path
            @stage_profile_templates_path ||= 
              config_finder[:application].stage_profile_templates_path.join(service_name)
          end

          def profile_templates(format: "erb")
            return @profile_templates unless @profile_templates.nil?
            @profile_templates = []
            [profile_templates_path, stage_profile_templates_path].each do |path|
              Dir.chdir(path) { @profile_templates |= Dir["**/*.#{format}"] } if path.directory?
            end
            @profile_templates.tap do |templates| 
              templates.reject! { |t| exclude_template?(t) }
            end
          end

          def exclude_template?(template); false; end

          def default_templates; task.opts.default_templates; end

          def init_profile
            return if default_templates.empty?
            puts "  Initializing #{service_name} profile"
            assure_dirs(profile_templates_path, stage_profile_path)
            upload_profile_templates
          end

          def update_profile
            assure_dirs(stage_profile_path)
            render_profile
            update_logrotate_files
          end

          protected

          def upload_profile_templates
            default_templates.each do |src_path|
              next unless file?(src_path)
              basename = src_path.basename
              dst_path = if src_path.extname == '.erb'
                           profile_templates_path
                         else
                           stage_profile_path
                         end.join(basename)
              print "    - #{basename}"
              if file?(dst_path)
                puts " [skipped]"
              else
                upload!(src_path, dst_path)
                puts " [created]"
              end
            end
          end

          def render_profile
            profile_templates.each { |template_file| render_profile_by_template(template_file) }
          end

          def render_profile_by_template(template_file)
            profile_file = stage_profile_path.join(template_file).sub_ext('')
            assure_dirs(profile_file.dirname)
            upload_by_template(file_to_upload: profile_file,
                               template_file: find_template_file(File.join(service_name, template_file)),
                               auto_revision: true)
          end

          def update_logrotate_files
            if file?(stage_profile_path.join(logrotate_file_name))
              logrotate_files.push(logrotate_file_path)
            end
          end
        end

        include Base
      end
    end
  end
end
