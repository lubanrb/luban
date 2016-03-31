module Luban
  module Deployment
    module Package
      DependencyTypes = %i(before_install after_install)

      class Dependency
        attr_reader :apply_to
        attr_reader :type
        attr_reader :name
        attr_reader :version
        attr_reader :options

        def initialize(apply_to, type, name, version, **opts)
          @apply_to = apply_to
          @type = type
          @name = name
          @version = version
          @options = opts
          validate
        end

        def applicable_to?(version)
          if @apply_to == :all
            true
          else
            Gem::Requirement.new(@apply_to).satisfied_by?(Gem::Version.new(version))
          end
        end

        protected

        def validate
          if @apply_to.nil?
            raise ArgumentError, 'The version requirement that the dependency applies to is NOT provided.'
          end
          unless DependencyTypes.include?(@type)
            raise ArgumentError, "Invalid dependency type: #{type.inspect}"
          end
          if @name.nil?
            raise ArgumentError, 'Dependency name is NOT provided.'
          end
          if @version.nil?
            raise ArgumentError, 'Dependency version is NOT provided.'
          end
        end
      end
    end
  end
end
