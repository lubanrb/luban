module Luban
  module Deployment
    module Package
      class DependencySet
        def initialize
          @dependencies = {} 
          @ctx = {}
        end

        def apply_to(version_requirement, &blk)
          @ctx = { version_requirement: version_requirement }
          instance_eval(&blk) if block_given?
        ensure
          @ctx = {}
        end

        def before_install(&blk)
          if @ctx[:version_requirement].nil?
            raise RuntimeError, 'Please call #apply_to prior to #before_install.'
          end
          @ctx[:type] = :before_install
          instance_eval(&blk) if block_given?
        end

        def after_install(&blk)
          if @ctx[:version_requirement].nil?
            raise RuntimeError, 'Please call #apply_to prior to #after_install.'
          end
          @ctx[:type] = :after_install
          instance_eval(&blk) if block_given?
        end

        def depend_on(name, version:, **opts)
          if @ctx[:type].nil?
            raise RuntimeError, 'Please call #before_install or #after_install prior to #depend_on.'
          end
          requirement = @ctx[:version_requirement]
          type = @ctx[:type]
          dependency = Dependency.new(requirement, type, name, version, **opts)
          unless @dependencies.has_key?(requirement)
            @dependencies[requirement] = { before_install: [],
                                           after_install: [] }
          end
          @dependencies[requirement][type] << dependency
        end

        def dependencies_for(version, type: nil)
          types = *type
          types = DependencyTypes if types.empty?
          deps = { before_install: [],
                   after_install: [] }
          @dependencies.each_pair do |r, d|
            types.each do |t|
              next if d[t].empty?
              deps[t] |= d[t] if d[t].first.applicable_to?(version)
            end
          end
          deps
        end

        def before_install_dependencies_for(version)
          dependencies_for(version, type: :before_install)
        end

        def after_install_dependencies_for(version)
          dependencies_for(version, type: :after_install)
        end
      end
    end
  end
end
