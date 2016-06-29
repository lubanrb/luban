module Luban
  module Deployment
    module Service
      class Base < Luban::Deployment::Package::Base
        include Luban::Deployment::Command::Tasks::Control

        def self.service_action(action, dispatch_to: nil, as: action, locally: false, &blk)
          define_method(action) do |args:, opts:|
            if current_version
              send("#{__method__}!", args: args, opts: opts.merge(version: current_version))
            else
              abort "Aborted! No current version of #{display_name} is specified."
            end
          end
          unless dispatch_to.nil?
            dispatch_task "#{action}!", to: dispatch_to, as: as, locally: locally, &blk
            protected "#{action}!"
          end
        end

        Luban::Deployment::Command::Tasks::Control::Actions.each do |action|
          service_action action, dispatch_to: :controller
        end
        %i(init_profile update_profile).each do |action| 
          service_action action, dispatch_to: :configurator, locally: true
        end

        alias_method :orig_init_profile, :init_profile

        def init_profile(args:, opts:)
          orig_init_profile(args: args, opts: opts.merge(default_templates: default_templates))
        end

        protected

        def set_parameters
          super
          linked_dirs.push('log', 'pids')
        end
      end
    end
  end
end