module Luban
  module Deployment
    module Service
      class Installer < Luban::Deployment::Package::Installer
        include Paths
      end
    end
  end
end