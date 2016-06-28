module Luban
  module Deployment
    class Application
      class Configurator < Worker
        include Luban::Deployment::Service::Configurator::Base
      end
    end
  end
end
