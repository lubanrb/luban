module Luban
  module Deployment
    module Packages
      class Ruby < Luban::Deployment::Package::Binary
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

        apply_to '>= 1.9.3' do
          before_install do
            depend_on 'openssl', version: '1.0.2e'
            depend_on 'yaml', version: '0.1.6'
          end
        end

        apply_to :all do
          after_install do
            depend_on 'bundler', version: '1.11.2'
          end
        end
        
        protected

        def setup_install_tasks
          super
          commands[:install].switch :install_doc, "Install Ruby document"
          commands[:install].option :bundler, "Bundler version"
        end

        def decompose_version(version)
          major_version, patch_level = version.split('-')
          patch_level = '' if patch_level.nil?
          patch_level = $1 if patch_level.match(/^p(\d+)$/)
          { major_version: major_version, patch_level: patch_level }
        end

        class Installer < Luban::Deployment::Package::Installer
          attr_reader :opt_dirs

          def install_doc?
            task.opts.install_doc
          end

          def ruby_executable
            @ruby_executable ||= bin_path.join('ruby')
          end

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
            unless install_doc?
              @configure_opts.unshift("--disable-install-doc") 
            end
            @opt_dirs = []
          end

          def compose_build_options
            @configure_opts << "--with-opt-dir=#{@opt_dirs.join(':')}"
            super
          end
        end
      end
    end
  end
end