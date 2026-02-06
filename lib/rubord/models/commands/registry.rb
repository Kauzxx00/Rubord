module Rubord
  class CommandRegistry
    def initialize
      @commands = {}
    end

    def register(klass, client, logCommands = true)
      name = klass.command_name
      raise "Command missing name" unless name
      
      @commands[name] = klass.new(client)
      
      Rubord::Logger.success "[Rubord:Commands] Registered command: #{name}" if logCommands
    end

    def get(name)
      @commands.find{ |_, c| c.name == name || c.aliases.include?(name)}&.last
    end

    def all
      @commands.values.freeze
    end
  end
end