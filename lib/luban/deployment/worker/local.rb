module Luban
  module Deployment
    module Worker
      class Local < Base
        def project_path
          @project_path ||= work_dir
        end

        def apps_path
          @apps_path ||= project_path.join('apps')
        end

        def app_path
          @app_path ||= apps_path.join(application)
        end
      end
    end
  end
end