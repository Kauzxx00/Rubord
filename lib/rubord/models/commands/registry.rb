module Rubord
  class CommandRegistry
    def initialize
      @commands = {}
      @command_classes = {}
    end

    def register(klass, client)
      name = klass.command_name
      raise "Command missing name" unless name
      
      @command_classes[name] = klass
      @commands[name] = klass.new(client)
      
      Rubord::Logger.success "[Rubord:Commands] Registered command: #{name}"
    end

    def get(name)
      @commands[name]
    end

    def all
      @commands.values.freeze
    end
  end
end