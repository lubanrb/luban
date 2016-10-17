require_relative 'gem'

module Luban
  module Deployment
    module Packages
      class RubygemsUpdate < Gem
        class Installer < Gem::Installer
          define_executable 'update_rubygems'

          def installed?
            return false unless file?(gem_executable)
            match?("#{gem_executable} -v", package_version)
          end

          protected

          def build_package
            super and update_rubygems! and uninstall_gem!
          end

          def update_rubygems!
            update_opts = "--no-rdoc --no-ri" unless install_doc?
            test("#{update_rubygems_executable} #{update_opts} >> #{install_log_file_path} 2>&1")
          end
        end
      end
    end
  end
end
