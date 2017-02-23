module Luban
  module Deployment
    class Application
      class Dockerizer < Worker
        attr_reader :build

        DefaultRevisionSize = 12

        def docker_templates_path
          task.opts.docker_templates_path
        end

        def default_docker_templates_path
          task.opts.default_docker_templates_path
        end

        def default_docker_tcp_port; docker_tls_verify? ? "2376" : "2375"; end

        def docker_tls_verify?; 
          host[:docker_tls_verify].nil? ? docker_tls_verify : host[:docker_tls_verify]
        end

        def docker_ca_cert_path; docker_cert_path.join("ca.pem"); end
        def docker_client_cert_path; docker_cert_path.join("cert.pem"); end
        def tls_key_path; docker_cert_path.join("key.pem"); end

        def tls_options
          ["--tlsverify", "--tlscacert #{docker_ca_cert_path}",
           "--tlscert #{docker_client_cert_path}", "--tlskey #{tls_key_path}"]
        end

        def docker_host
          unix_socket = host[:docker_unix_socket] || docker_unix_socket
          if unix_socket.nil?
            tcp_port = host[:docker_tcp_port] || docker_tcp_port || default_docker_tcp_port
            "tcp://#{hostname}:#{tcp_port}"
          else
            "unix://#{unix_socket}"
          end
        end

        def docker_options
          @docker_options ||= ["-H #{docker_host}"].concat(docker_tls_verify? ? tls_options : [])
        end

        def revision_size
          task.opts.revision_size || DefaultRevisionSize
        end

        def init_docker
          puts "  Initializing #{application_name} docker profile"
          docker_templates.each do |path|
            print "    - #{path}"
            src_path = default_docker_templates_path.join(path)
            dst_path = docker_templates_path.join(path)
            if file?(dst_path)
              puts "  [skipped]"
            else
              upload!(src_path, dst_path)
              puts "  [created]"
            end
          end
        end

        def dockerize_application
          rmdir(build[:path]) if force?
          dockerize_application!
          case build[:status]
          when :succeeded
            update_result "Successfully dockerized #{build[:image_tag]}."
          when :skipped
            update_result "Skipped! ALREADY dockerized #{build[:image_tag]}.", status: :skipped
          else
            update_result "FAILED to dockerize #{build[:image_tag]}.", status: :failed, level: :error
          end
          update_result build: build
        end

        def get_image_id(docker_options = [])
          capture(:docker, docker_options.join(' '), :images, "-q", build[:image_tag])
        end

        def built?
          !(build[:image_id] = get_image_id).empty?
        end

        def build_application
          if built?
            update_result "Skipped! ALREADY built #{build[:image_tag]}.", status: :skipped
            return
          end
          output = compose_application!

          if built?
            update_result "Successfully built #{build[:image_tag]}."
          else
            update_result "FAILED to build #{build[:image_tag]}: #{output}.", 
                          status: :failed, level: :error
          end
        end

        def distributed?
          build[:image_id] == get_image_id(docker_options)
        end

        def distribute_application
          if distributed?
            update_result "Skipped! ALREADY distributed #{build[:image_tag]}.", status: :skipped
            return
          end
          output = distribute_application!

          if distributed?
            update_result "Successfully distributed #{build[:image_tag]}."
          else
            update_result "FAILED to distribute #{build[:image_tag]}: #{output}", 
                          status: :failed, level: :error
          end
        end

        protected

        def init
          super
          @build = task.opts.build || init_build
        end

        def init_build
          (@build = {}).tap do |b|
            b[:path] = build_path
            b[:context] = context_path
            b[:dockerfile] = dockerfile
            b[:compose_file] = compose_file
            b[:compose_env_file] = compose_env_file
            b[:sources] = init_build_sources
            b[:archives] = init_build_archives
            b[:revision] = compose_revision
            b[:image_tag] = image_tag(b[:revision])
          end
        end

        def init_build_sources
          sources = { packages: packages_path }
          releases = get_releases(releases_path, type: 'app')
          if releases.has_key?(:"app.bundler")
            sources[:"app.bundler"] = releases.delete(:"app.bundler")
          end
          sources.merge!(releases)
          profile_path = releases_path.dirname.join('profile')
          profile = directory?(profile_path) ? get_releases(profile_path, type: 'profile') : {}
          sources["env.#{stage}".to_sym] = app_path
          sources.merge!(profile)
          sources.inject({}) do |srcs, (name, path)|
            md5 = md5_for_dir(path)
            srcs[name] = { path: path, md5: md5, tag: md5[0, revision_size] }
            srcs
          end
        end

        def compose_revision
          require 'digest/md5'
          revisions = build[:sources].inject('') { |r, (_, src)| r += src[:md5] }
          Digest::MD5.hexdigest(revisions)[0, revision_size]
        end

        def init_build_archives
          build[:sources].each_key.inject(build[:archives] = {}) do |archives, name|
            archives[name] = { path: archive_file_path("#{name}-#{build[:sources][name][:tag]}") }
            archives
          end
        end

        def archive_file_name(name)
          "#{project}-#{application}-#{name}.#{archive_file_extname}"
        end

        def archive_file_extname; "tar.xz"; end

        def archive_file_path(name)
          build[:context].join(archive_file_name(name))
        end

        def build_path; docker_path.join("build-#{stage}-#{build_tag}"); end
        def context_path; build_path.join('context'); end
        def image_tag(revision); "#{project}-#{application}-#{stage}:#{build_tag}-#{revision}"; end
        def dockerfile; build[:context].join("Dockerfile"); end
        def compose_file; build[:path].join("docker-compose.yml"); end
        def compose_env_file; build[:path].join(".env"); end

        def get_releases(path, type:)
          capture(:ls, '-xtd', path.join('*')).split.
            collect { |p| File.basename(p) }.
            inject({}) { |r, t| r["#{type}.#{t}".to_sym] = path.join(t); r }
        end

        def get_packages
          packages.inject({}) do |pkgs, (name, package)|
            pkgs[name] = package.class.required_packages_for(package.current_version).inject(
                          { versions: package.installable_versions.join(', '),
                            current_version: package.current_version }) do |pkg, (type, deps)|
                          deps.each { |d| pkg["#{type}.#{d.name}".to_sym] = d.version }
                          pkg
                        end
            pkgs
          end
        end

        def dockerize_application!
          assure_dirs(build[:context])
          package_application!
          render_dockerfile
          render_compose_env_file
          render_compose_file
          build[:status] = status
        end

        def package_application!
          build[:archives].each_pair do |name, archive|
            source = build[:sources][name]
            archive[:status] = 
              if file?(archive[:path]) and archive[:path].basename.to_s =~ /#{source[:tag]}/
                :skipped
              else
                execute(:tar, "-cJf", archive[:path], source[:path]) ? :succeeded : :failed
              end
          end
        end

        def render_dockerfile
          upload_by_template(file_to_upload: build[:dockerfile],
                             template_file: find_template_file('Dockerfile.erb'),
                             auto_revision: true)
        end

        def render_compose_env_file
          upload_by_template(file_to_upload: build[:compose_env_file],
                             template_file: find_template_file('docker-compose-env.erb'),
                             auto_revision: true)
        end

        def render_compose_file
          upload_by_template(file_to_upload: build[:compose_file],
                             template_file: find_template_file('docker-compose.yml.erb'),
                             auto_revision: true)
        end

        def status
          build[:archives].each_value.inject(:skipped) do |status, archive|
            if archive[:status] == :failed
              status = :failed; break
            end
            if archive[:status] == :succeeded
              status = :succeeded 
            end
            status
          end
        end

        def compose_application!
          within build[:path] { capture(:"docker-compose", :build, "2>&1") }
        end

        def distribute_application!
          capture(:docker, :save, build[:image_tag], "|", 
                  :docker, docker_options.join(' '), "load", "2>&1")
        end

        def remove_image!(docker_options = [], image_id)
          execute(:docker, docker_options.join(' '), :rmi, image_id, "2>/dev/null")
        end

        def docker_templates(format: "erb")
          @docker_templates ||= 
            if default_docker_templates_path.directory?
              Dir.chdir(default_docker_templates_path) { Dir["**/*.#{format}"] }
            else
              []
            end
        end
      end
    end
  end
end
