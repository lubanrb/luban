module Luban
  module Deployment
    module Packages
      class Popt < Luban::Deployment::Package::Base
        class Installer < Luban::Deployment::Package::Installer
          def header_file
            @header_file ||= include_path.join('popt.h')
          end

          def shared_obj_file
            @shared_obj_file ||= lib_path.join("libpopt.#{lib_extension}")
          end

          def source_repo
            @source_repo ||= "http://rpm5.org"
          end

          def source_url_root
            @source_url_root ||= "files/popt"
          end

          def installed?
            file?(header_file) and file?(shared_obj_file)
          end

          protected

          def configure_build_options
            super
            @configure_opts.unshift("--disable-static")
          end
          
          def update_binstubs!; end
        end
      end
    end
  end
end
