module Rubord
  class CommandBase
    class << self
      attr_reader :command_name, :description_text

      def name(value)
        @command_name = value.to_s
      end

      def description(value)
        @description_text = value.to_s
      end
    end

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def run(_message)
      raise NotImplementedError, "Command must implement #run"
    end
  end
end