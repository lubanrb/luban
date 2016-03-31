module Luban
  module Deployment
    module Worker
      class Controller < Base
        def bin_path
          @bin_path ||= install_path.join('bin')
        end
      end
    end
  end
end