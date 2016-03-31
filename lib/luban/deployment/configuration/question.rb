module Luban
  module Deployment
    class Configuration
      class Question
        attr_reader :prompt, :default

        def initialize(default:, prompt: nil, echo: true)
          @default = default
          @echo = echo
          @prompt = "#{prompt.to_s}: " unless prompt.nil?
        end

        def echo?; @echo; end

        def call
          ask_question
          get_response
        end

        protected

        def ask_question
          $stdout.print prompt
        end

        def get_response
          response = if echo?
                       $stdin.gets.chomp
                     else
                       require 'io/console'
                       $stdin.noecho(&:gets).chomp.tap{ $stdout.print "\n" }
                     end
          response.empty? ? default : response
        end
      end
    end
  end
end