module Luban
  module Deployment
    module Service
      class Installer < Luban::Deployment::Package::Installer
        include Worker::Base
      end
    end
  end
end
