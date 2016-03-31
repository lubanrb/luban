module Luban
  module Deployment
    module Package
      class Installer < Worker
        # Shared library file extension name based on OS
        LibExtensions = { 
          Linux:  'so',   # Linux
          Darwin: 'dylib' # OSX 
        }
        DefaultLibExtension = 'so'

        attr_reader :configure_opts
        attr_reader :build_env_vars

        def currently_used_by
          parent.currently_used_by
        end

        def current_symlinked?
          current_package_version == package_version
        end

        def current_configured?; task.opts.current; end
        alias_method :current?, :current_configured?

        def current_package_version
          if symlink?(current_path)
            File.basename(readlink(current_path))
          else
            nil
          end
        end

        def default_configure_opts
          @default_configure_opts ||= []
        end

        protected

        def init
          super
          configure_build_env_variables        
          configure_build_options
        end

        def configure_build_env_variables          
          @build_env_vars = { 
            ldflags: [ENV['LDFLAGS'].to_s],
            cflags: [ENV['CFLAGS'].to_s],
            cppflags: [ENV['CPPFLAGS'].to_s]
          }
          if child?
            configure_parent_build_env_variables
            configure_parent_build_options
          end
        end

        def configure_parent_build_env_variables
          parent.build_env_vars[:ldflags] << "-L#{lib_path}"
          parent.build_env_vars[:cflags] << "-I#{include_path}"
          parent.build_env_vars[:cppflags] << "-I#{include_path}"
        end

        def configure_parent_build_options
          if parent.respond_to?("with_#{package_name}_dir")
            parent.send("with_#{package_name}_dir", install_path)
          end
        end

        def compose_build_env_variables
          build_env_vars.inject({}) do |vars, (k, v)|
            vars[k] = "'#{v.join(' ').strip}'" unless v.all?(&:empty?)
            vars
          end
        end

        def configure_build_options
          @configure_opts = default_configure_opts | (task.opts.__remaining__ || [])
          @configure_opts.unshift(install_prefix)
        end

        def compose_build_options
          @configure_opts.reject(&:empty?).join(' ')
        end

        def install_prefix
          "--prefix=#{install_path}"
        end

        def validate; end

        def lib_extension
          @lib_extension ||= LibExtensions.fetch(os_name.to_sym, DefaultLibExtension)
        end
      end
    end
  end
end
