require 'luban/cli'

module Luban
  module Deployment
    class Runner < Luban::CLI::Application
      using Luban::CLI::CoreRefinements
      include Luban::Deployment::Helpers::Configuration
      include Luban::Deployment::Parameters::General

      def default_rc
        @default_rc ||= { 'luban_roles' => %i(app),
                          'luban_root_path' => Parameters::General::DefaultLubanRootPath,
                          'stages' => %w(development staging production),
                          'author' => { 'name' => 'author name', 'email' => 'author@email.com' },
                          'user' => current_user
                        }
      end

      def lubanfile; @lubanfile ||= 'Lubanfile.rb'; end

      def config_file
        @config_file ||= work_dir.join(lubanfile)
      end

      def new_project?; !!@new_project; end

      def init_project(args:, opts:)
        if new_project?
          project args[:project]
          if project == '.'
            work_dir Pathname.pwd
            project work_dir.basename(".deploy").to_s
          end
        end
        singleton_class.send(:include, Luban::Deployment::Helpers::Generator::Project)
        create_project_skeleton
      end

      protected

      def on_configure
        super
        if set_work_dir
          setup_cli_with_projects
        else
          setup_cli_without_projects
        end
      end

      def set_default_common_parameters
        %i(luban_roles luban_root_path stages author user).each { |p| set_default p, rc[p.to_s] }
      end

      def set_default_project_parameters
        set_default :applications, find_applications
        set_default :project, File.basename(work_dir)
      end

      def find_applications
        apps_path.children.select(&:directory?).map(&:basename).map(&:to_s)
      end

      def set_work_dir
        project_root = find_lubanfile
        unless project_root.nil?
          work_dir Pathname.new(project_root)
          apps_path work_dir.join('apps')
        end
      end

      def find_lubanfile
        original = current = Dir.pwd
        until File.exist?(lubanfile)
          Dir.chdir('..')
          return nil if Dir.pwd == current
         current = Dir.pwd
        end
        current
      ensure
        Dir.chdir(original)
      end

      def load_libraries
        require "#{work_dir}/lib/project"
      end

      def project_base_class
        Object.const_get(project.camelcase)
      end

      def setup_cli_with_projects
        @new_project = false
        load_configuration_file(config_file)
        set_default_common_parameters
        set_default_project_parameters
        load_libraries

        version Luban::Deployment::VERSION
        desc "Manage the deployment of project #{project.camelcase}"
        setup_init_project
        setup_projects
      end

      def setup_projects
        stages.each { |stg| setup_project(stg) }
      end

      def setup_project(stg)
        stg = stg.to_sym
        commands[stg] = project_class(stg).new(self, stg)
      end

      def project_class(stg)
        mod = Object.const_set(stg.camelcase, Module.new)
        mod.const_set(project.camelcase, Class.new(project_base_class))
      end

      def setup_cli_without_projects
        @new_project = true
        set_default_common_parameters

        version Luban::Deployment::VERSION
        desc "Framework to manage project deployment"
        
        setup_init_project
      end

      def setup_init_project
        _self = self
        command :init do
          desc 'Initialize a Luban deployment project'
          if _self.new_project?
            argument :project, 'Project name', required: true, assure: ->(name) { !name.empty? }
          end
          action! :init_project
        end
      end
    end
  end
end
