module Luban
  module Deployment
    module Package
      class Service < Binary
        include Luban::Deployment::Command::Tasks::Deploy
        include Luban::Deployment::Command::Tasks::Control

        %i(deploy).each do |m|
          define_task_method(m, worker: :deployer)
        end

        protected

      end
    end
  end
end