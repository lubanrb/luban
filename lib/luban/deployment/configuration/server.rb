require 'set'

module Luban
  module Deployment
    class Configuration
      class Server < SSHKit::Host
        attr_reader :roles

        def self.create(host, **properties)
          server = host.is_a?(Server) ? host : Server.new(host)
          server.add_properties(properties) unless properties.empty?
          server.ssh_options ||= {}
          server
        end

        def roles
          self[:roles]
        end

        def add_roles(roles)
          roles.each { |role| add_role(role) }
        end 
        alias_method :roles=, :add_roles

        def add_role(role)
          roles.add(role.to_sym)
        end

        def has_role?(role)
          roles.include? role.to_sym
        end

        def properties
          @properties ||= { :roles => Set.new }
        end

        def [](key)
          properties[key] 
        end
        alias_method :fetch, :[]

        def []=(key, value)
          if respond_to?("#{key}=")
            send("#{key}=", value)
          else
            pval = properties[key]
            if pval.is_a? Hash and value.is_a? Hash
              pval.merge!(value)
            elsif pval.is_a? Set and value.is_a? Set
              pval.merge(value)
            elsif pval.is_a? Array and value.is_a? Array
              pval.concat value
            else
              properties[key] = value
            end
          end 
        end
        alias_method :set, :[]=

       def add_properties(_properties)
          _properties.each { |k, v| self[k] = v }
        end

        def primary?
          self[:primary]
        end
      end
    end
  end
end