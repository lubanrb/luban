require 'ostruct'

module Luban
  module Deployment
    module Worker
      class Task
        attr_reader :cmd
        attr_reader :args
        attr_reader :opts
        attr_reader :result

        def initialize(task)
          @cmd = task[:cmd]
          @args = OpenStruct.new(task[:args])
          @opts = OpenStruct.new(task[:opts])
          @result = OpenStruct.new
        end

        def to_h
          { cmd: cmd, args: args.to_h, opts: opts.to_h, result: result.to_h }
        end
      end
    end
  end
end