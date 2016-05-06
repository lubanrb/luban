module Luban
  module Deployment
    module Package
      class Installer < Worker; end
    end
  end
end

require_relative 'installer/core'
require_relative 'installer/paths'
require_relative 'installer/install'
