module Luban
  module Deployment
    class Script < Luban::Deployment::Application
      def controllable?; false; end
    end
  end
end