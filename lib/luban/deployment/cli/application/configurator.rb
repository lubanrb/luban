module Luban
  module Deployment
    class Application
      class Configurator < Worker
        include Luban::Deployment::Service::Configurator::Base

        def default_source_path
          task.opts.source[:from]
        end

        def default_source_template_path
          raise NotImplementedError, "#{self.class.name}#default_source_template_path is an abstract method."
        end

        def init_source
          if directory?(default_source_path)
            puts "  Skipped! ALREADY initialized #{application_name} default source"
          else
            puts "  Initializing #{application_name} default source"
            cp('-r', default_source_template_path, default_source_path)
          end
        end
      end
    end
  end
end
