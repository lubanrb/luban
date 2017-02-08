module Luban
  module Deployment
    module Package
      class Installer
        class InstallFailure < Luban::Deployment::Error; end

        def src_file_md5
          @src_file_md5 ||= File.file?(src_md5_file_path) ? File.read(src_md5_file_path).chomp : ''
        end

        def required_packages
          @required_packages ||= 
            self.class.package_class(package_name).
              required_packages_for(package_major_version)
        end

        def configure_executable
          @configure_executable ||= './configure'
        end

        def installed?
          raise NotImplementedError, "#{self.class.name}#installed? is an abstract method."
        end

        def downloaded?
          file?(src_file_path)
        end

        def cached?
          md5_matched?(src_cache_path, src_file_md5)
        end

        def validate_download_url
          info "Validating download URL for #{package_full_name}"
          validate_download_url!
        end

        def download
          info "Downloading #{package_full_name}"
          if downloaded?
            create_src_md5_file unless file?(src_md5_file_path)
            update_result "Skipped! #{package_full_name} has been downloaded ALREADY."
          else
            download_package!
            if downloaded?
              create_src_md5_file unless file?(src_md5_file_path)
              update_result "Successfully downloaded #{package_full_name}."
            else
              update_result "Failed to download #{package_full_name}. " + 
                            "Please check install log for details: #{install_log_file_path}",
                            status: :failed, level: :error
            end
          end
        end

        def install
          info "Installing #{package_full_name}"
          if installed?
            if force?
              install!
            else
              return update_result("Skipped! #{package_full_name} has been installed ALREADY.", 
                                   status: :skipped)
            end
          else
            install!
          end

          if installed?
            update_result "Successfully installed #{package_full_name}."
          else
            update_result "Failed to install #{package_full_name}. " +
                          "Please check install log for details: #{install_log_file_path}",
                          status: :failed, level: :error
          end
        end

        def uninstall
          info "Uninstalling #{package_full_name}"
          if installed?
            if current? and !force?
              update_result "Skippped! #{package_full_name} is the current version in use. " +
                            "Please switch to other version before uninstalling this version or " +
                            "use -f to force uninstalling.",
                            status: :skipped, level: :warn
            else
              uninstall!
              update_result "#{package_full_name} is uninstalled. "
            end
          else
            message = "#{package_full_name} is NOT installed."
            if directory?(install_path) or directory?(build_path)
              if force?
                uninstall!
                update_result message + 
                              "Cleaned up leftover of #{package_full_name} from last installation."
              else
                update_result message +
                              "But leftover from last installation is found. " +
                              "Use -f to force clean it up."
              end
            else
              update_result "Skipped! #{message}"
            end
          end
        end

        def cleanup_all
          cleanup_temp!
          cleanup_logs!
          update_result "Cleaned up temporary files in #{package_full_name} installation"
        end

        def get_summary
          status = if current_symlinked?
                     current? ? " *" : "s*"
                   else
                     current? ? "c*" : (deprecated? ? " d" : "  ")
                    end

          if installed?
            installed = 'installed'
            alert = case status
                    when "s*"
                      "Alert! #{package_full_name} is not the current version but symlinked IMPROPERLY. " +
                      "Run \"binstubs\" to fix it."
                    when "c*"
                      "Alert! #{package_full_name} is set as current version but NOT symlinked properly. " +
                      "Run \"binstubs\" to fix it."
                    end
          else
            installed = 'NOT installed'
            alert = nil
          end
          update_result summary: { name: package_full_name, installed: installed, 
                                   status: status, alert: alert }
        end

        def update_binstubs
          if current?
            if installed?
              update_binstubs!
              update_result "Updated #{package_name} binstubs/symlinks with current version #{package_version}"
            else
              update_result "Skipped! #{package_full_name} is NOT installed yet. Please install it first.",
                            status: :failed, level: :error
            end
          else
            if current_symlinked?
              remove_binstubs!
              remove_symlinks!
              update_result "Removed #{package_name} binstubs/symlinks with version #{package_version}. " +
                            "Current version of #{package_name} is NOT specified.",
                            level: :warn
            end
          end
        end

        def which_current
          get_summary.tap do |result|
            result.summary[:executable] = "Not found"
            if current? and current_symlinked? and
               file?(executable = File.join(readlink(current_path), 'bin', task.args.executable))
              result.summary[:executable] = executable
            end
          end
        end

        def whence_origin
          get_summary.tap do |result|
            result.summary[:executable] = "Not found"
            if file?(executable = bin_path.join(task.args.executable))
              result.summary[:executable] = executable
            end
          end
        end

        protected

        def before_download
          unless downloaded?
            bootstrap_download
            validate_download_url
          end
          download_required_packages(:before_install)
        end

        def after_download
          download_required_packages(:after_install)
        end

        def download_required_packages(type)
          manage_required_packages(type, :download)
        end

        def manage_required_packages(type, cmd)
          required_packages[type].each do |d|
            version = task.opts.send(d.name) || d.version
            next if version == 'default'
            version = self.class.package_class(d.name).latest_version if version == 'latest'
            self.class.worker_class(:installer, package: d.name).new(
              config: config, backend: backend,
              cmd: cmd, args: {},
              opts: d.options.merge(name: d.name, version: version, 
                                    current: true, parent: self).
                              merge(self.class.package_class(d.name).decompose_version(version))
            ).run
          end
        end

        def before_install
          bootstrap_install
          install_required_packages(:before_install)          
        end

        def after_install
          install_required_packages(:after_install)
          update_binstubs
        end

        def install_required_packages(type)
          manage_required_packages(type, :install)
        end

        def validate_download_url!
          unless url_exists?(download_url)
            raise InstallFailure, 
                  "Package #{package_full_name} is NOT found from url: #{download_url}."
          end
        end

        def install!
          cleanup_build! # Cleanup leftover from last install if any
          upload_package
          uncompress_package
          build_package
          cleanup_build!
        end

        def uninstall!
          if current?
            remove_binstubs!
            remove_symlinks! 
          end
          rmdir(install_path)
          cleanup_temp!
          cleanup_logs!
        end

        def cleanup_temp!
          Luban::Deployment::Package::DependencyTypes.each do |type|
            required_packages[type].each do |d|
              self.class.worker_class(:installer, package: d.name).new(
                config: config, backend: backend, 
                cmd: :cleanup_all, args: {}, 
                opts: d.options.merge(name: d.name, version: d.version, parent: self)
              ).run
            end
          end
          cleanup_build!
        end

        def cleanup_build!
          rmdir(build_path)
        end

        def cleanup_logs!
          rmdir(install_log_path)
        end

        def update_binstubs!
          remove_binstubs!
          remove_symlinks!
          create_symlinks!
          create_binstubs!
        end

        def create_symlinks!
          ln(install_path, current_path)
        end

        def create_binstubs!
          return unless directory?(bin_path)
          find_cmd = "find #{bin_path}/* -type f -print && find #{bin_path}/* -type l -print"
          capture(find_cmd).split("\n").each do |bin|
            ln(bin, app_bin_path.join(File.basename(bin)))
          end
        end

        def remove_symlinks!
          symlink?(current_path) and rm(current_path)
        end

        def remove_binstubs!
          return unless directory?(current_bin_path)
          find_cmd = "find #{current_bin_path}/* -type f -print && find #{current_bin_path}/* -type l -print"
          capture(find_cmd).split("\n").each do |bin|
            bin_symlink = app_bin_path.join(File.basename(bin))
            symlink?(bin_symlink) and rm(bin_symlink)
          end
        end

        def bootstrap_download
          assure_dirs(package_downloads_path)
        end

        def bootstrap_install
          assure_dirs(tmp_path, app_bin_path, 
                      package_tmp_path, install_path, install_log_path)
        end

        def download_package!
          unless test(:curl, "-L -o #{src_file_path} #{download_url}")
            rm(src_file_path)
            abort_action('download')
          end
        end

        def create_src_md5_file
          execute(:echo, "#{md5_for_file(src_file_path)} > #{src_md5_file_path}")
        end

        def upload_package
          info "Uploading #{package_full_name} source package"
          if cached?
            info "#{package_full_name} is uploaded ALREADY"
          else
            upload_package!
          end
        end

        def upload_package!
          upload!(src_file_path.to_s, src_cache_path.to_s)
          unless md5_matched?(src_cache_path, src_file_md5)
            rm(src_cache_path)
            abort_action('upload')
          end
        end

        def uncompress_package
          info "Uncompressing #{package_full_name} source package"
          uncompress_package!
        end

        def uncompress_package!
          unless test("tar -xzf #{src_cache_path} -C #{package_tmp_path} >> #{install_log_file_path} 2>&1")
            abort_action('uncompress')
          end
        end

        def build_package
          within build_path do
            configure_package
            make_package
            install_package
          end
        end

        def configure_package
          info "Configuring #{package_full_name}"
          abort_action('configure') unless configure_package!
        end

        def configure_package!
          test(configure_executable, 
               "#{compose_build_options} >> #{install_log_file_path} 2>&1")
        end

        def make_package
          info "Making #{package_full_name}"
          abort_action('make') unless make_package!
        end

        def make_package!
          test(:make, ">> #{install_log_file_path} 2>&1")
        end

        def install_package
          info "Installing #{package_full_name}"
          abort_action('install') unless install_package!
        end

        def install_package!
          test(:make, "install >> #{install_log_file_path} 2>&1")
        end

        def abort_action(action)
          cleanup_temp!
          task.result.status = :failed
          task.result.message = "Failed to #{action} package #{package_full_name}." +
                                "Please check install log for details: #{install_log_file_path}" 
          raise InstallFailure, task.result.message
        end
      end
    end
  end
end
