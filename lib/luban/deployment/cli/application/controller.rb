module Luban
  module Deployment
    class Application
      class Controller < Worker
        include Luban::Deployment::Service::Controller::Base

        def current_release?(_release_tag)
          _release_tag =~ /^#{Regexp.escape(application_version)}/
        end

        def current_symlinked?(_release_tag)
          _release_tag == release_tag
        end

        def release_path
          @release_path ||= Pathname.new(readlink(current_app_path))
        end

        def releases_path
          @releases_path ||= release_path.dirname
        end

        def release_tag
          @release_tag ||= release_path.basename.to_s
        end

        def show_current
          update_result get_summary(release_tag)
        end

        def show_summary
          update_result get_summary(*get_releases)
        end

        def get_releases
          capture(:ls, '-xt', releases_path).split
        end

        protected

        def get_status(tag)
          if current_symlinked?(tag)
            current_release?(tag) ? " *" : "s*"
          else
            (current_release?(tag) and !current_release?(release_tag)) ? "c*" : "  "
          end
        end

        def get_summary(*release_tags)
          release_tags.inject([]) do |r, tag|
            r.push "#{get_status(tag)} #{application_name}:#{tag} (published)"
          end.join("\n")
        end
      end
    end
  end
end
