module Luban
  module Deployment
    class Application
      class Repository < Luban::Deployment::Worker::Base
        using Luban::CLI::CoreRefinements
        include Luban::Deployment::Worker::Paths::Local

        DefaultRevisionSize = 12

        attr_reader :type
        attr_reader :from
        attr_reader :scm
        attr_reader :revision
        attr_reader :rev_size

        def scm_module
          require_relative "scm/#{scm}"
          @scm_module ||= SCM.const_get(scm.camelcase)
        end

        def workspace_path
          @workspace_path ||= app_path.join('.luban')
        end

        def clone_path
          @clone_path ||= workspace_path.join('repositories').join(type)
        end

        def releases_path
          @releases_path ||= workspace_path.join('releases').join(type)
        end

        def release_package_path
          @release_package_path ||= releases_path.join(release_package_file_name)
        end

        def release_package_file_name
          @release_package_file_name ||= "#{release_package_name}.#{release_package_extname}"
        end

        def release_package_name
          @release_package_name ||= "#{release_prefix}-#{release_tag}"
        end

        def release_package_extname
          @release_package_extname ||= 'tgz'
        end

        def release_prefix
          @release_prefix ||= "#{stage}-#{project}-#{application}-#{type}"
        end

        def release_tag
          @release_tag ||= "#{stage}-#{revision}"
        end

        def bundle_without
          @bundle_without ||= %w(development test)
        end

        # Description on abstract methods:
        #   available?: check if the remote repository is available
        #   cloned?: check if the remote repository is cloned locally
        #   fetch_revision: retrieve the signature/checksum of the commit that will be deployed
        #   clone: clone a new copy of the remote repository
        #   update: update the clone of the remote repository
        #   release: copy the contents of cloned repository onto the release path
        [:available?, :cloned?, :fetch_revision, :clone, :update, :release].each do |method|
          define_method(method) do
            raise NotImplementedError, "\#{self.class.name}##{__method__} is an abstract method."
          end
        end

        def build
          assure_dirs(clone_path, releases_path)
          if cloned? and !force?
            update_revision
            update_result "Skipped! Local #{type} repository has been built ALREADY.", status: :skipped
          else
            if available?
              if build!
                update_revision
                update_result "Successfully built local #{type} repository."
              else
                update_result "FAILED to build local #{type} repository!", status: :failed, level: :error
              end
            else
              update_result "Aborted! Remote #{type} repository is NOT available.", status: :failed, level: :error
            end
          end
        end

        def package
          if cloned?
            if package!
              cleanup_releases
              update_result "Successfully package local #{type} repository to #{release_package_path}.", 
                            release: { type: type, tag: release_tag,
                                       path: release_package_path, 
                                       md5: md5_for_file(release_package_path),
                                       bundled_gems: bundle_gems }
            else
              update_result "FAILED to package local #{type} repository!", status: :failed, level: :error
            end
          else
            update_result "Aborted! Local #{type} package is NOT built yet!", status: :failed, level: :error
          end
        end

        protected

        def init
          @rev_size = DefaultRevisionSize
          task.opts.repository.each_pair { |name, value| instance_variable_set("@#{name}", value) }
          load_scm
        end

        def load_scm
          singleton_class.send(:prepend, scm_module)
        end

        def build!
          rmdir(clone_path)
          clone
        end

        def package!
          if update
            update_revision
            release
          end
        end

        def update_revision
          @revision = fetch_revision
        end

        def cleanup_releases
          files = capture(:ls, '-xt', releases_path).split
          if files.count > keep_releases
            within(releases_path) do
              files.last(files.count - keep_releases).each { |f| rm(f) }
            end
          end
        end

        def bundle_gems
          gemfile_path = Pathname.new(release_tag).join('Gemfile')
          gems_cache = Pathname.new('vendor').join('cache')
          bundle_path = Pathname.new('vendor').join('bundle')
          bundled_gems = {}
          gems = bundled_gems[:gems] = {}
          if test(:tar, "-tzf #{release_package_path} #{gemfile_path} > /dev/null 2>&1")
            within(workspace_path) do
              execute(:tar, "--strip-components=1 -xzf #{release_package_path} #{gemfile_path}")
              unless test(:bundle, :check, "--path #{bundle_path}")
                execute(:bundle, :install, "--path #{bundle_path} --without #{bundle_without.join(' ')} --quiet")
                info "Package gems bundled in Gemfile"
                execute(:bundle, :package, "--all --quiet")
              end
              gem_files = capture(:ls, '-xt', gems_cache.join('*.gem')).split
              gem_files.each do |gem_file|
                gem_name = File.basename(gem_file)
                md5_file = "#{gem_file}.md5"
                gems[gem_name] =
                  if file?(md5_file)
                    gems[gem_name] = capture(:cat, md5_file)
                  else
                    md5_for_file(gem_file).tap { |md5|
                      execute(:echo, "#{md5} > #{md5_file}")
                    }
                  end
              end
            end
            bundled_gems[:gems_cache] = workspace_path.join(gems_cache)
            workspace_path.join('Gemfile.lock').tap do |p|
              bundled_gems[:locked_gemfile] = { path: p, md5: md5_for_file(p) }
            end
          end
          bundled_gems
        end
      end
    end
  end
end