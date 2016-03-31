module Luban
  module Deployment
    class Configuration
      def roles(*names)
        opts = names.last.is_a?(::Hash) ? names.pop : {}
        filter_servers(servers.find_by_roles(filter_roles(names), opts))
      end

      def release_roles(*names)
        if names.last.is_a?(Hash)
          names.last.merge(:exclude => :no_release)
        else
          names << { :exclude => :no_release }
        end
        roles(*names)
      end

      def primary(role)
        servers.find_primary(role)
      end

      protected

      def filter_roles(_roles)
        available_roles = (env_filter(:roles) | config_filter(:roles)).map(&:to_sym)
        available_roles = servers.available_roles if available_roles.empty?
        if _roles.include?(:all)
          available_roles
        else
          _roles.select { |name| available_roles.include?(name) }
        end
      end

      def filter_servers(_servers)
        filter_hosts = env_filter(:hosts) | config_filter(:hosts)
        if filter_hosts.empty?
          _servers
        else
          _servers.select { |server| filter_hosts.include?(server.hostname) }
        end
      end

      def env_filter(type)
        type = type.to_s.upcase
        ENV[type].nil? ? [] : ENV[type].split(',')
      end

      def config_filter(type)
        filter = fetch(:filter) || fetch(:select)
        filter.nil? ? [] : filter.fetch(type, [])
      end
    end
  end
end