module Luban
  module Deployment
    class Application
      class Controller < Worker
        include Luban::Deployment::Service::Controller::Base

        def current_configured?; !!task.opts.release[:current]; end
        alias_method :current?, :current_configured?

        def current_symlinked?
          release_tag == current_release_tag
        end

        def current_release_tag
          if symlink?(current_app_path)
            File.basename(readlink(current_app_path))
          else
            nil
          end
        end

        def published?; directory?(release_path); end
        def deprecated?; !!task.opts.release[:deprecated]; end

        def get_summary
          status = if current_symlinked?
                     current? ? " *" : "s*"
                   else
                     current? ? "c*" : (deprecated? ? " d" : "  ")
                   end

          if published?
            published = 'published'
            alert = case status
                    when "s*"
                      "Alert! #{application_name}:#{release_tag} is not the current version but symlinked IMPROPERLY. "
                    when "c*"
                      "Alert! #{application_name}:#{release_tag} is set as current version but NOT symlinked properly. "
                    end
          else
            published = 'NOT published'
            alert = nil
          end
          update_result summary: { name: "#{application_name}:#{release_tag}", published: published,
                                   status: status, alert: alert }
        end
      end
    end
  end
end
