module Luban
  module Deployment
    module Packages
      class Yaml < Luban::Deployment::Package::Binary
        class Installer < Luban::Deployment::Package::Installer
          def header_file
            @header_file ||= include_path.join('yaml.h')
          end

          def shared_obj_file
            @shared_obj_file ||= lib_path.join("libyaml.#{lib_extension}")
          end

          def source_repo
            @source_repo ||= "http://pyyaml.org"
          end

          def source_url_root
            @source_url_root ||= "download/libyaml"
          end

          def installed?
            file?(header_file) and file?(shared_obj_file)
          end

          protected
          
          def update_binstubs!; end
        end
      end
    end
  end
end
