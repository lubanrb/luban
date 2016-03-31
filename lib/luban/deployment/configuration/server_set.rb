module Luban
  module Deployment
    class Configuration
      class ServerSet
        include Enumerable

        def initialize
          @servers = { :all => [] } 
        end

        def all
          @servers[:all]
        end

        def available_roles
          @servers.keys - [:all]
        end

        def has_server?(server)
          all.find do |s|
            s.user == server.user and
            s.hostname == server.hostname and
            s.port == server.port
          end
        end

        def add_host(host, **properties)
          new_server = Server.create(host, properties)
          if server = has_server?(new_server)
            server.user = new_server.user unless new_server.user.nil?
            server.port = new_server.port unless new_server.port.nil?
            server.add_properties(properties)
            server
          else
            all << new_server
            new_server.roles.each do |role| 
              @servers[role] ||= []
              @servers[role] << new_server
            end
            new_server
          end
        end

        def add_hosts_for_role(role, hosts, **properties)
          properties_deepcopy = Marshal.dump(properties.merge(:roles => Array(role)))
          Array(hosts).each { |host| add_host(host, Marshal.load(properties_deepcopy)) }
        end

        def find_by_roles(roles, **opts)
          roles.inject([]) do |result, role|
            result.concat(find_by_role(role, opts))
          end
        end

        def find_by_role(role, **opts)
          if @servers.has_key?(role)
            opts.inject(@servers[role]) do |_servers, (action, key)|
              send(action, _servers, key)
            end
          else
            []
          end
        end

        def find_primary(role)
          _servers = find_by_role(role)
          _servers.find(&:primary?) || _servers.first
        end

        def each
          all.each { |server| yield server }
        end

        protected

        def exclude(_servers, key)
          _servers.select { |server| !server[key] }
        end

        def filter(_servers, key)
          _servers.select { |server| server[key] }
        end
      end
    end
  end
end