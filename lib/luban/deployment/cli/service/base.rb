module Luban
  module Deployment
    module Service
      class Base < Luban::Deployment::Package::Base
        include Luban::Deployment::Command::Tasks::Deploy
        include Luban::Deployment::Command::Tasks::Control

        ControlActions = Luban::Deployment::Command::Tasks::Control::Actions
        ProfileActions = %i(update_profile)

        (ControlActions | ProfileActions).each do |m|
          define_method(m) do |args:, opts:|
            if current_version
              send("#{__method__}!", args: args, opts: opts.merge(version: current_version))
            else
              abort "Aborted! No current version of #{display_name} is specified."
            end
          end
        end

        protected

        def on_configure
          super
          include_default_templates_path if respond_to?(:default_templates_path, true)
        end

        def include_default_templates_path
          if default_templates_path.is_a?(Pathname)
            default_templates_paths.unshift(default_templates_path)
          else
            abort "Aborted! Default templates path for #{self.class.name} MUST be a Pathname."
          end
        end

        def set_parameters
          super
          linked_dirs.push('log', 'pids')
        end

        ControlActions.each do |task|
          dispatch_task "#{task}!", to: :controller, as: task
        end

        dispatch_task :update_profile!, to: :configurator, as: :update_profile, locally: true
      end
    end
  end
end