module Rubord
  class CommandRegistry
    def initialize
      @commands = {}
    end

    def register(klass, client)
      name = klass.command_name
      raise "Command missing name" unless name

      @commands[name] = klass.new(client)
    end

    def get(name)
      @commands[name]
    end

    def all
      @commands.values
    end
  end
end