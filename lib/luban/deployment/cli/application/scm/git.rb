module Luban
  module Deployment
    class Application
      class Repository
        module SCM
          module Git
            def git_cmd; :git; end

            def available?
              test(git_cmd, 'ls-remote --heads', from)
            end

            def cloned?
              file?(clone_path.join("HEAD")) and from == remote_origin
            end

            def remote_origin
              within(clone_path) { capture(git_cmd, "config --get remote.origin.url 2>/dev/null") }
            end

            def fetch_revision
              within(clone_path) { capture(git_cmd, "rev-parse --short=#{rev_size} #{version} 2>/dev/null") }
              #within(clone_path) { capture(git_cmd, "rev-list --max-count=1 --abbrev-commit --abbrev=rev_size #{version}") }
            end

            def clone
              test(git_cmd, :clone, '--mirror', from, clone_path)
            end

            def update
              within(clone_path) { test(git_cmd, :remote, :update, "--prune") }
            end

            def release
              within(clone_path) { test(git_cmd, :archive, version, "--format=#{release_package_extname} --prefix=#{release_tag}/ -o #{release_package_path}") }
            end

            def branch?
              within(clone_path) { test(git_cmd, :"show-ref", "--quite --verify refs/heads/#{version}") }
            end

            def tag?
              within(clone_path) {test(git_cmd, :"show-ref", "--quite --verify refs/tags/#{version}") }
            end

            def commit?
              version =~ /^\h+/ and !revision.nil?
            end

            def release_tag
              @release_tag ||= commit? ? "ref-#{revision}" : super
            end
          end
        end
      end
    end
  end
end
