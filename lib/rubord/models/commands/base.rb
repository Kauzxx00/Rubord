module Rubord
  # Base class for creating commands.
  #
  # @example Creating a simple command
  #   class PingCommand < Rubord::CommandBase
  #     name "ping"
  #     description "Responds with pong"
  #
  #     # @yieldparam message [Rubord::Message] The message that triggered the command
  #     def run(message)
  #       message.reply("Pong!")
  #     end
  #   end
  #
  # @abstract
  class CommandBase
    class << self
      attr_reader :command_name,
                  :description_text,
                  :command_usage,
                  :aliases_list

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@aliases_list, [])
      end

      def name(value)
        @command_name = value.to_s
      end

      def description(value)
        @description_text = value.to_s
      end

      def aliases(*values)
        @aliases_list.concat(values.map(&:to_s))
      end

      def validate!
        raise ArgumentError, "Command #{self} is missing a name" unless @command_name
      end
    end

    attr_reader :client

    def initialize(client)
      @client = client
      self.class.validate!
    end

    # @return [String]
    def name
      self.class.command_name
    end

    # @return [String]
    def description
      self.class.description_text
    end

    # @return [Array<String>]
    def aliases
      self.class.aliases_list
    end

    # Executes the command.
    #
    # @param message [Rubord::Message]
    # @param args [Array<String>]
    # @abstract
    def run(_message, _args = [])
      raise NotImplementedError, "#{self.class} must implement #run(message)"
    end

    def inspect
      attrs = []
      attrs << "name=#{name.inspect}" if name
      attrs << "aliases=#{aliases.inspect}" unless aliases.empty?

      "#<#{self.class} #{attrs.join(' ')}>"
    end
  end
end