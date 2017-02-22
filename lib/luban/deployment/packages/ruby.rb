module Luban
  module Deployment
    module Packages
      class Ruby < Luban::Deployment::Package::Base
        apply_to '1.8.6' do
          after_install do
            depend_on 'rubygems', version: '1.3.7'
          end
        end

        apply_to '1.8.7' do 
          after_install do
            depend_on 'rubygems', version: '1.6.2'
          end
        end

        apply_to '<= 1.8.7' do
          before_install do
            depend_on 'openssl', version: '0.9.8zh'
          end
        end

        apply_to '1.9.1' do
          before_install do
            depend_on 'yaml', version: '0.1.6'
          end
          after_install do
            depend_on 'rubygems', version: '1.3.7'
          end
        end

        apply_to '1.9.2' do
          before_install do
            depend_on 'yaml', version: '0.1.6'
          end
          after_install do
            depend_on 'rubygems', version: '1.8.23'
          end
        end

        apply_to [">= 1.9.3", "< 2.1.2"] do
          before_install do
            depend_on 'yaml', version: '0.1.6'
          end
        end

        apply_to [">= 1.9.3", "< 2.4.0"] do
          before_install do
            depend_on 'openssl', version: '1.0.2k'
          end
        end

        apply_to '>= 2.4.0' do
          before_install do
            depend_on 'openssl', version: '1.1.0e'
          end
        end

        apply_to '>= 1.9.3' do
          after_install do
            depend_on 'rubygems', version: '2.6.10'
          end
        end

        apply_to :all do
          after_install do
            depend_on 'bundler', version: '1.14.4'
          end
        end
        
        def self.decompose_version(version)
          major_version, patch_level = version.split('-')
          patch_level = '' if patch_level.nil?
          patch_level = $1 if patch_level.match(/^p(\d+)$/)
          { major_version: major_version, patch_level: patch_level }
        end
        
        protected

        def setup_provision_tasks
          super

          provision_tasks[:install].switch :install_static, "Install static Ruby library"
          provision_tasks[:install].switch :install_doc, "Install Ruby document"
          provision_tasks[:install].switch :install_tcl, "Install with Tcl"
          provision_tasks[:install].switch :install_tk, "Install with Tk"
          provision_tasks[:install].option :rubygems, "Rubygems version"
          provision_tasks[:install].option :bundler, "Bundler version"
          provision_tasks[:install].option :openssl, "OpenSSL version (effective for v1.9.3 or above)"
        end

        class Installer < Luban::Deployment::Package::Installer
          attr_reader :opt_dirs

          def install_static?
            task.opts.install_static
          end

          def install_doc?
            task.opts.install_doc
          end

          def install_tcl?
            task.opts.install_tcl
          end

          def install_tk?
            task.opts.install_tk
          end

          define_executable 'ruby'

          def gem_executable
            @gem_executable ||= bin_path.join('gem')
          end

          def source_repo
            @source_repo ||= "https://cache.ruby-lang.org"
          end

          def source_url_root
            @source_url_root ||= "pub/ruby/#{package_major_version.gsub(/\.\d+$/, '')}"
          end

          def installed?
            return false unless file?(ruby_executable)
            pattern = Regexp.escape(package_major_version)
            unless package_patch_level.empty?
              pattern += ".*#{Regexp.escape(package_patch_level)}"
            end
            match?("#{ruby_executable} -v", Regexp.new(pattern))
          end

          def with_opt_dir(dir)
            @opt_dirs << dir
          end
          alias_method :with_openssl_dir, :with_opt_dir
          alias_method :with_yaml_dir, :with_opt_dir

          protected

          def configure_build_options
            super
            @configure_opts.unshift("--disable-install-doc") unless install_doc?
            @configure_opts << "--enable-shared" unless install_static?
            @configure_opts << "--without-tcl" unless install_tcl?
            @configure_opts << "--without-tk" unless install_tk?
            @opt_dirs = []
          end

          def compose_build_options
            @configure_opts << "--with-opt-dir=#{@opt_dirs.join(':')}"
            super
          end

          def after_install
            super
            create_symlinks_for_header_files
            remove_static_library unless install_static?
          end

          def create_symlinks_for_header_files
            if !header_file_exists?("ruby/version.h") and
               (source_path = find_header_file("version.h"))
              assure_dirs(target_path = source_path.dirname.join('ruby'))
              ln(source_path, target_path.join('version.h'))
            end
            if !header_file_exists?("ruby/io.h") and
               (source_path = find_header_file("*/rubyio.h"))
              assure_dirs(target_path = source_path.dirname.join('ruby'))
              ln(source_path, target_path.join('io.h'))
            end
          end

          def find_header_file(file)
            f = capture(:find, install_path.to_s, "-wholename '*/#{file}'")
            f.empty? ? nil : Pathname.new(f)
          end

          def header_file_exists?(file); !!find_header_file(file); end

          def remove_static_library
            rm(install_path.join('lib', 'libruby-static.a'))
          end
        end
      end
    end
  end
end
