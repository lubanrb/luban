module Luban
  module Deployment
    class Application
      class Repository
        module SCM
          module Git
            attr_reader :tag
            attr_reader :branch

            def git_cmd; :git; end

            def ref
              tag || branch || @ref
            end

            def available?
              test(git_cmd, 'ls-remote --heads', from)
            end

            def cloned?
              file?(clone_path.join("HEAD"))
            end

            def fetch_revision
              within(clone_path) { capture(git_cmd, "rev-parse --short=#{rev_size} #{ref}") }
              #within(clone_path) { capture(git_cmd, "rev-list --max-count=1 --abbrev-commit --abbrev=rev_size #{ref}") }
            end

            def clone
              test(git_cmd, :clone, '--mirror', from, clone_path)
            end

            def update
              within(clone_path) { test(git_cmd, :remote, :update, "--prune") }
            end

            def release
              within(clone_path) { test(git_cmd, :archive, ref, "--prefix=#{release_tag}/ -o #{release_package_path}") }
            end

            def release_tag
              @release_tag ||= "#{ref}-#{revision}"
            end
          end
        end
      end
    end
  end
end
