module Luban
  module Deployment
    class Application
      class Publisher < Worker
        include Luban::Deployment::Helpers::LinkedPaths

        def release_type; task.opts.release_pack[:type]; end
        def release_version; task.opts.release_pack[:version]; end
        def release_tag; task.opts.release_pack[:tag]; end
        def release_package_path; task.opts.release_pack[:path]; end
        def release_md5; task.opts.release_pack[:md5]; end
        def bundled_gems; task.opts.release_pack[:bundled_gems]; end
        def locked_gemfile; bundled_gems[:locked_gemfile]; end
        def gems_source; bundled_gems[:gems_cache]; end
        def gems; bundled_gems[:gems]; end

        def publish_app?; release_type == 'app'; end
        def publish_profile?; release_type == 'profile'; end

        def release_name
          @release_name ||= "#{application}:#{release_type}:#{release_tag}"
        end

        def releases_path
          @releases_path ||= super.dirname.join(release_type)
        end

        def releases_log_path
          @releases_log_path ||= app_path.join('releases.log')
        end

        def bundle_config_path
          @bundle_config_path ||= shared_path.join('.bundle')
        end

        def bundle_path
          @bundle_path ||= shared_path.join('vendor', 'bundle')
        end

        def gems_cache_path
          @gems_cache_path ||= shared_path.join('vendor', 'cache')
        end

        def bundle_without
          @bundle_without ||= %w(development test)
        end

        def bundle_flags
          @bundle_flags ||= %w(--deployment --quiet)
        end

        def bundle_linked_dirs
          @bundle_linked_dirs ||= %w(.bundle vendor/cache vendor/bundle)
        end

        def published?; directory?(release_path); end

        def publish
          assure_dirs(releases_path)
          if published?
            if force?
              rmdir(release_path)
              publish!
            else
              update_result "Skipped! ALREADY published #{release_name}.", status: :skipped
              return
            end
          else
            publish!
          end

          if published?
            update_result "Successfully published #{release_name}."
          else
            update_result "FAILED to publish #{release_name}.", status: :failed, level: :error
          end
        end

        def deprecate
          if directory?(release_path)
            rmdir(release_path)
            update_result "Successfully deprecated published release #{release_name}."
          end
        end

        def after_publish
          create_symlinks
          bundle_gems if has_gemfile?
        end

        protected

        def publish!
          rollout_release
          send("cleanup_#{release_type}_releases")
        end

        def rollout_release
          upload_to = app_tmp_path.join(release_package_path.basename)
          upload!(release_package_path.to_s, upload_to.to_s)
          if md5_matched?(upload_to, release_md5) and
             test(:tar, "-xzf #{upload_to} -C #{releases_path}")
            touch(release_path)
            create_symlinks
            update_releases_log
          else
            rmdir(release_path)
          end
        ensure
          rm(upload_to)
        end

        def create_symlinks
          send("create_#{release_type}_symlinks")
          if has_gemfile?
            create_linked_dirs(bundle_linked_dirs, to: release_path)
          end
        end

        def create_profile_symlinks
          create_release_symlink(shared_path)
        end

        def create_app_symlinks
          create_release_symlink(app_path)
          assure_linked_dirs
          create_symlinks_for_linked_dirs
          create_symlinks_for_linked_files
          create_symlinks_for_archived_logs
        end

        def create_release_symlink(target_dir)
          assure_symlink(release_path, target_dir.join(release_type))
        end

        def create_symlinks_for_linked_dirs
          create_linked_dirs(to: release_path)
        end

        def create_symlinks_for_linked_files
          create_linked_files(to: release_path)
        end

        def update_releases_log
          execute %{echo "[$(date -u)][#{user}] #{release_log_message}" >> #{releases_log_path}}
        end

        def release_log_message
          "#{release_name} in #{stage} #{project} is published successfully."
        end

        def cleanup_releases(keep_releases = 1)
          files = capture(:ls, '-xtd', releases_path.join("#{release_version}-*")).split(" ")
          if files.count > keep_releases
            files.last(files.count - keep_releases).each { |f| rmdir(f) }
          end
        end

        def cleanup_app_releases; cleanup_releases(5); end
        def cleanup_profile_releases; cleanup_releases; end

        def bundle_gems
          assure_dirs(bundle_config_path, gems_cache_path, bundle_path)
          sync_gems_cache
          sync_locked_gemfile
          with_clean_env { install_gems_from_cache }
        end

        def sync_gems_cache
          return if md5_matched?(gems_cache_path, gems_source[:md5])
          gems.each_pair do |gem_name, md5|
            gem_path = gems_cache_path.join(gem_name)
            unless md5_matched?(gem_path, md5)
              if File.file?(gem_file = gems_source[:path].join(gem_name))
                upload!(gem_file.to_s, gem_path.to_s)
              else
                upload!("#{gem_file.to_s}/", gem_path.to_s, recursive: true)
              end
            end
          end
        end

        def sync_locked_gemfile
          gemfile_lock_path = release_path.join(locked_gemfile[:path].basename)
          unless md5_matched?(gemfile_lock_path, locked_gemfile[:md5])
            upload!(locked_gemfile[:path].to_s, gemfile_lock_path.to_s)
          end
        end

        def install_gems_from_cache
          options = []
          options << "--gemfile #{gemfile}"
          options << "--path #{bundle_path}"
          unless test(bundle_executable, :check, *options)
            options << "--local"
            unless bundle_without.include?(stage.to_s)
              options << "--without #{bundle_without.join(' ')}"
            end
            options << bundle_flags.join(' ')
            execute(bundle_executable, :install, *options)
          end
        end
      end
    end
  end
end
