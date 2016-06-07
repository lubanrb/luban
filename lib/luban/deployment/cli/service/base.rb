module Luban
  module Deployment
    module Service
      class Base < Luban::Deployment::Package::Base
        include Luban::Deployment::Command::Tasks::Deploy
        include Luban::Deployment::Command::Tasks::Control

        def self.service_action(name, dispatch_to: nil, locally: false, &blk)
          define_method(name) do |args:, opts:|
            if current_version
              send("#{__method__}!", args: args, opts: opts.merge(version: current_version))
            else
              abort "Aborted! No current version of #{display_name} is specified."
            end
          end
          unless dispatch_to.nil?
            dispatch_task "#{name}!", to: dispatch_to, as: name, locally: locally, &blk
            protected "#{name}!"
          end
        end

        Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
          service_action action, dispatch_to: :controller
        end
        service_action :update_profile, dispatch_to: :configurator, locally: true

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
      end
    end
  end
end