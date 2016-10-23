module Luban
  module Deployment
    class Configuration
      attr_reader :variables
      attr_reader :servers

      def initialize
        @variables = {}
        @servers = ServerSet.new
      end

      def set(key, value)
        @variables[key] = value  
      end

      def set_default(key, value)
        set(key, value) if @variables[key].nil?
      end

      def delete(key)
        @variables[key] = value
      end

      def fetch(key, default = nil, &blk)
        value = if block_given?
                  @variables.fetch(key, &blk)
                else
                  @variables.fetch(key, default)
                end
        while callable_without_parameters?(value) 
          value = set(key, value.call)
        end
        return value
      end

      def keys
        @variables.keys
      end

      def has_key?(key)
        @variables.has_key?(key)
      end

      def role(name, hosts, **properties)
        if name == :all
          raise ArgumentError, 'Reserved role name, :all, is NOT allowed to use.'
        end
        @servers.add_hosts_for_role(name, hosts, properties)
      end

      def server(name, **properties)
        new_server = servers.add_host(name, properties)
        if new_server
          new_server.ssh_options = fetch(:ssh_options) || {}
        end
      end

      def ask(key=nil, default:, prompt: nil, echo: true)
        Question.new(default: default, prompt: prompt, echo: echo).call.tap do |answer|
          set(key, answer) unless key.nil?
        end
      end

      protected

      def callable_without_parameters?(x)
        x.respond_to?(:call) && (!x.respond_to?(:arity) || x.arity == 0)
      end
    end
  end
end