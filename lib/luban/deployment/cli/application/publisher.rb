module Luban
  module Deployment
    class Application
      class Publisher < Luban::Deployment::Worker::Base
        include Luban::Deployment::Worker::Paths::Remote

        def release_name; task.opts.release[:name]; end
        def release_tag; task.opts.release[:tag]; end
        def release_package_path; task.opts.release[:path]; end
        def release_md5; task.opts.release[:md5]; end
        def bundled_gems; task.opts.release[:bundled_gems]; end
        def locked_gemfile; bundled_gems[:locked_gemfile]; end
        def gems_source; bundled_gems[:gems_cache]; end
        def gems; bundled_gems[:gems]; end

        def publish_app?; release_name == 'app'; end
        def publish_profile?; release_name == 'profile'; end

        def display_name
          @display_name ||= "#{application} #{release_name} (release: #{release_tag})"
        end

        def releases_path
          @releases_path ||= super.join(release_name)
        end

        def release_path
          @release_path ||= releases_path.join(release_tag)
        end

        def releases_log_path
          @releases_log_path ||= app_path.join('releases.log')
        end

        def gemfile
          @gemfile ||= release_path.join('Gemfile')
        end

        def bundle_cmd
          @bundle_cmd ||= app_bin_path.join('bundle')
        end

        def bundle_config_path
          @bundle_config_path ||= shared_path.join('.bundle')
        end

        def bundle_path
          @bundle_path ||= shared_path.join('vendor').join('bundle')
        end

        def gems_cache_path
          @gems_cache_path ||= shared_path.join('vendor').join('cache')
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

        def published?
          get_releases.include?(release_tag)
        end

        def publish
          assure_dirs(releases_path)
          if published?
            if force?
              publish!
            else
              update_result "Skipped! #{display_name} has been published ALREADY.", status: :skipped
              return
            end
          else
            publish!
          end

          if published?
            update_result "Successfully published #{display_name}."
          else
            update_result "Failed to publish #{display_name}", status: :failed, level: :error
          end
        end

        def after_publish
          create_symlinks
          bundle_gems
        end

        protected

        def get_releases
          capture(:ls, '-xt', releases_path).split
        end

        def publish!
          rollout_release
          cleanup_releases
        end

        def rollout_release
          upload_to = app_tmp_path.join(release_package_path.basename)
          upload!(release_package_path.to_s, upload_to.to_s)
          if md5_matched?(upload_to, release_md5) and
             test(:tar, "-xzf #{upload_to} -C #{releases_path}")
            create_symlinks
            update_releases_log
          else
            rm(release_path)
          end
        ensure
          rm(upload_to)
        end

        def create_symlinks
          send("create_#{release_name}_symlinks")
        end

        def create_profile_symlinks
          create_release_symlink(shared_path)
          create_shared_symlinks_for(:directory, linked_dirs)
          create_shared_symlinks_for(:directory, bundle_linked_dirs) if file?(gemfile)
        end

        def create_app_symlinks
          create_release_symlink(app_path)
          create_shared_symlinks_for(:directory, linked_dirs | %w(profile))
          create_shared_symlinks_for(:directory, bundle_linked_dirs) if file?(gemfile)
          create_shared_symlinks_for(:file, linked_files)
        end

        def create_release_symlink(target_dir)
          assure_symlink(release_path, target_dir.join(release_name))
        end

        def create_shared_symlinks_for(type, linked_paths)
          linked_paths.each do |path|
            target_path = release_path.join(path)
            assure_dirs(target_path.dirname)
            source_path = shared_path.join(path)
            assure_symlink(source_path, target_path)
          end
        end

        def update_releases_log
          execute %{echo "[$(date -u)][#{user}] #{release_log_message}" >> #{releases_log_path}}
        end

        def release_log_message
          "Release #{display_name} in #{stage} #{project} is published successfully."
        end

        def cleanup_releases
          releases = get_releases
          if releases.count > keep_releases
            releases_to_keep = releases.first(keep_releases)
            unless releases_to_keep.include?(release_tag)
              releases_to_keep[-1] = release_tag
            end
            releases_to_remove = releases - releases_to_keep
            releases_to_remove.each do |release| 
              rm(releases_path.join(release))
            end
            info "Removed #{releases_to_remove.count} old releases."
          else
            info "No old releases to remove (keeping most recent #{keep_releases} releases)."
          end
        end

        def bundle_gems
          assure_dirs(bundle_config_path, gems_cache_path, bundle_path)
          sync_gems_cache
          sync_locked_gemfile
          install_gems_from_cache
        end

        def sync_gems_cache
          capture(:ls, '-xt', gems_cache_path).split.each do |gem_name|
            rm(gems_cache_path.join(gem_name)) unless gems.has_key?(gem_name)
          end
          gems.each_pair do |gem_name, md5|
            gem_path = gems_cache_path.join(gem_name)
            unless md5_matched?(gem_path, md5)
              upload!(gems_source.join(gem_name).to_s, gem_path.to_s)
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
          within(release_path) do
            options = []
            options << "--gemfile #{gemfile}"
            options << "--path #{bundle_path}"
            unless test(bundle_cmd, :check, *options)
              options << "--without #{bundle_without.join(' ')}"
              options << bundle_flags.join(' ')
              execute(bundle_cmd, :install, *options)
            end
          end
        end
      end
    end
  end
end
