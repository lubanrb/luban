require 'fileutils'

module Luban
  module Deployment
    module Helpers
      module Generator
        using Luban::CLI::CoreRefinements

        module Utils
          def mkdir(path)
            if path.directory?
              puts " [skipped]"
            else
              FileUtils.mkdir(path)
              puts " [created]"
            end
          end

          def copy_file(src_path, dst_path)
            if dst_path.file?
              puts " [skipped]"
            else
              FileUtils.cp(src_path, dst_path)
              puts " [created]"
            end
          end

          def render_file(template_path, output_path, context: binding)
            if output_path.file?
              puts " [skipped]"
            else
              require 'erb'
              File.open(output_path, 'w') do |f|
                f.write ERB.new(File.read(template_path), nil, '<>').result(context)
              end
              puts " [created]"
            end
          end
        end

        module Base
          protected

          include Utils

          def skeletons_path
            @skeletons_path ||= 
              Pathname.new(__FILE__).dirname.join('..', 'templates').realpath
          end

          def copy_dir(src_path, dst_path, stages: [], depth: 1)
            indent = '  ' * depth
            print  indent + "- #{dst_path.basename}"
            mkdir(dst_path)
            src_files = []
            src_path.each_child do |p|
              if p.directory?
                if placeholder?(p.basename)
                  stages.each do |s| 
                    copy_dir(p, dst_path.join(staged_basename(s, p.basename)), depth: depth + 1)
                  end
                else
                  copy_dir(p, dst_path.join(p.basename), stages: stages, depth: depth + 1)
                end
              else
                src_files << p
              end
            end
            src_files.each do |f|
              basename = f.basename
              action = :copy_file
              if basename.extname == '.erb'
                basename = basename.sub_ext('')
                action = :render_file
              end
              if placeholder?(basename)
                stages.each do |stage|
                  n = staged_basename(stage, basename)
                  print indent + "  - #{n}"
                  send(action, f, dst_path.join(n), context: binding)
                end
              else
                print indent + "  - #{basename}"
                send(action, f, dst_path.join(basename))
              end
            end
          end

          def placeholder?(basename)
            basename.to_s =~ /^__stage/
          end

          def staged_basename(stage, basename)
            basename.to_s.sub!(/^__stage/, stage)
          end
        end

        module Project
          include Base

          def project_skeleton_path
            @project_skeleton_path ||= skeletons_path.join('project')
          end

          def project_target_path
            @project_target_path ||= (work_dir or Pathname.pwd.join(project))
          end

          def create_project_skeleton
            puts "Creating skeleton for project #{project.camelcase}"
            copy_dir(project_skeleton_path, project_target_path, stages: stages)
          end
        end

        module Application
          include Base

          def application_skeleton_path
            @application_skeleton_path ||= skeletons_path.join('application')
          end

          def application_target_path
            @application_target_path ||= apps_path.join(application)
          end

          def application_class_name
            "#{project}:#{application}".camelcase
          end

          def create_application_skeleton
            puts "Creating skeleton for #{stage} application #{application_class_name}"
            copy_dir(application_skeleton_path, application_target_path, stages: [stage])
          end
        end
      end
    end
  end
end
