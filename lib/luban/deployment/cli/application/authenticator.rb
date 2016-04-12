module Luban
  module Deployment
    class Application
      class Authenticator < Luban::Deployment::Worker::Base
        def private_key_file_name
          @private_key_file_name ||= "id_#{authen_key_type}"
        end

        def authen_keys_path
          @authen_keys_path ||= Pathname.new(user_home).join('.ssh')
        end

        def private_key_file_path
          @private_key_file ||= authen_keys_path.join(private_key_file_name)
        end

        def public_key_file_path
          @public_key_file_path ||= authen_keys_path.join("#{private_key_file_name}.pub")
        end

        def authorized_keys_file_path
          @authorized_keys_file_path ||= authen_keys_path.join('authorized_keys')
        end

        def public_key
          @public_key ||= get_public_key
        end

        def keyget_command
          @keyget_command ||= "cat #{public_key_file_path} 2>&1"
        end

        def keygen_command
          @keygen_command ||= "ssh-keygen -t #{authen_key_type} -f #{private_key_file_path} -N '' 2>&1"
        end

        def get_public_key
          generate_key_pairs
          capture(keyget_command)
        end

        def generate_key_pairs
          execute(keygen_command) unless key_pairs_generated?
        end

        def key_pairs_generated?
          file?(private_key_file_path) and file?(public_key_file_path)
        end

        def app; task.opts.app; end

        def promptless_authen
          if promptless_authen_enabled?
            update_result "Skipped! Promptless authentication has been enabled ALREADY.",
                          status: :skipped, public_key: public_key
          else
            setup_password_authen
            generate_key_pairs
            add_authorized_keys
            update_result "Promptless authentication is enabled.", public_key: public_key
          end
        end

        def promptless_authen_enabled?
          origin_auth_methods = host.ssh_options[:auth_methods]
          host.ssh_options[:auth_methods] = %w(publickey)
          capture('echo ok') == 'ok'
        rescue Net::SSH::AuthenticationFailed
          false
        ensure
          if origin_auth_methods.nil?
            host.ssh_options.delete(:auth_methods)
          else
            host.ssh_options[:auth_methods] = origin_auth_methods
          end
        end

        protected

        def setup_password_authen
          host.user, host.password = user, nil if host.user.nil?
          host.password = app.password_for(host.user) if host.password.nil?
          host.ssh_options[:auth_methods] = %w(keyboard-interactive password)
        end

        def add_authorized_keys
          public_keys = task.opts.public_keys || []
          public_keys.uniq!
          if file?(authorized_keys_file_path)
            public_keys.each { |k| add_authorized_key(k) unless key_authorized?(k) }
          else
            public_keys.each { |k| add_authorized_key(k) }
          end
        end

        def add_authorized_key(key)
          execute("umask 077; echo #{key} >> #{authorized_keys_file_path} 2>&1")
        end

        def key_authorized?(key)
          test("grep -v \"^#\" #{authorized_keys_file_path} | grep -Fxq \"#{key}\"")
        end
      end
    end
  end
end