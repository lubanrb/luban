require_relative 'gem'

module Luban
  module Deployment
    module Packages
      class Bundler < Gem
        class Installer < Gem::Installer
          define_executable 'bundler'

          def installed?
            return false unless file?(bundler_executable)
            with_clean_env { match?("#{bundler_executable} -v", package_version) }
          end

          protected

          def build_package
            if file?(bundler_executable)
              uninstall_gem! and super
            else
              super
            end
          end
        end
      end
    end
  end
end
