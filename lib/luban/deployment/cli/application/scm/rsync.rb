module Luban
  module Deployment
    class Application
      class Repository
        module SCM
          module Rsync
            def init
              super
              @from = Pathname.new(@from) unless from.is_a?(Pathname)
            end

            def rsync_cmd; :rsync; end

            def available?; directory?(from); end

            def cloned?
              directory?(clone_path) and 
              test("[ \"$(ls -A #{clone_path})\" ]") # Not empty
            end

            def fetch_revision
              # Use MD5 as the revision
              capture(:tar, "-cf - #{clone_path} 2>/dev/null | openssl md5")[/\h+$/][0, rev_size]
            end

            def clone
              test(rsync_cmd, "-acz", "#{from}/", clone_path)
            end

            def update
              test(rsync_cmd, "-acz", "--delete", "#{from}/", clone_path)
            end

            def release
              within(releases_path) do
                assure_dirs(release_tag)
                execute(:tar, "-C #{clone_path} -cf - . | tar -C #{release_tag} -xf -")
                execute(:tar, "-czf", release_package_path, release_tag)
                rm(release_tag)
              end
            end
          end
        end
      end
    end
  end
end
