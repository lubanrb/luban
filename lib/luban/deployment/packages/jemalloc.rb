module Luban
  module Deployment
    module Packages
      class Jemalloc < Luban::Deployment::Package::Base
        protected

        def setup_provision_tasks
          super
          provision_tasks[:install].switch :enable_debug, "Build debugging code"
          provision_tasks[:install].switch :jemalloc_prefix, "Prefix to prepend to all public APIs"
        end

        class Installer < Luban::Deployment::Package::Installer
          define_executable 'jemalloc-config'

          def source_repo
            @source_repo ||= "https://github.com"
          end

          def source_url_root
            @source_url_root ||= "jemalloc/jemalloc/releases/download/#{package_version}"
          end

          def src_file_extname
            @src_file_extname ||= 'tar.bz2'
          end

          def installed?
            return false unless file?(jemalloc_config_executable)
            match?("#{jemalloc_config_executable} --version", package_version)
          end

          def enable_debug?
            task.opts.enable_debug
          end

          def jemalloc_prefix
            task.opts.jemalloc_prefix
          end

          protected

          def configure_build_options
            super
            @configure_opts.push("--disable-debug") unless enable_debug?
            @configure_opts.push("--with-jemalloc-prefix=#{jemalloc_prefix}")
          end

          def uncompress_option
            @uncompress_option ||= 'j'
          end
        end
      end
    end
  end
end
