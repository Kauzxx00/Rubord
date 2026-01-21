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
                  :aliases_list,
                  :cooldown_seconds,
                  :guild_only_flag,
                  :dm_only_flag

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@aliases_list, [])
        subclass.instance_variable_set(:@cooldown_seconds, 0)
        subclass.instance_variable_set(:@guild_only_flag, false)
        subclass.instance_variable_set(:@dm_only_flag, false)
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

      def cooldown(seconds)
        @cooldown_seconds = seconds.to_i
      end

      def guild_only(value = true)
        @guild_only_flag = value
      end

      def dm_only(value = true)
        @dm_only_flag = value
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

    # @return [Integer]
    def cooldown
      self.class.cooldown_seconds
    end

    def guild_only?
      self.class.guild_only_flag
    end

    def dm_only?
      self.class.dm_only_flag
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
      "#<#{self.class} name=#{command_name.inspect}>"
    end
  end
end