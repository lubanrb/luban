module Luban
  module Deployment
    class Application
      module Dockerable
        def self.prepended(base)
          base.dispatch_task :init_docker!, to: :dockerizer, as: :init_docker, locally: true
          base.dispatch_task :dockerize_application!, to: :dockerizer, as: :dockerize_application, locally: true
          base.dispatch_task :build_application!, to: :dockerizer, as: :build_application, locally: true
          base.dispatch_task :distribute_application!, to: :dockerizer, as: :distribute_application
        end

        def deploy(args:, opts:)
          super
          dockerize_application!(args: args, opts: opts)[:build].tap do |build|
            build_application!(args: args, opts: opts.merge(build: build))
            distribute_application!(args: args, opts: opts.merge(build: build))
          end
        end

        def init_profiles(args:, opts:)
          super
          init_docker!(args: args, 
                       opts: opts.merge(default_docker_templates_path: default_docker_templates_path,
                                        docker_templates_path: config_finder[:application].templates_path))
        end

        def default_docker_templates_path
          @default_docker_template_path ||= base_templates_path(__FILE__)
        end

        protected

        %i(setup! install_all! uninstall_all! destroy! 
           binstubs! which! whence!
           cleanup_packages! cleanup_application!
           show_current_packages! show_summary_packages! get_summary
           publish_release! deprecate_published_release!
           deploy_profile!).each do |action|
          define_method("#{action}") do |args:, opts:|
            super(args: args, opts: opts.merge(locally: true))
          end
        end
      end
    end
  end
end
