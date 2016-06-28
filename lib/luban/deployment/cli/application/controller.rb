module Luban
  module Deployment
    class Application
      class Controller < Worker
        include Luban::Deployment::Service::Controller::Base
      end
    end
  end
end
