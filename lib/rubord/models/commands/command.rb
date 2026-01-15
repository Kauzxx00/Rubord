require_relative "base.rb"
require_relative "loader.rb"
require_relative "registry.rb"

module Rubord
  def process_command(message)
    return unless message.content.start_with?(@prefix)

    args = message.content[@prefix.length..].split
    name = args.shift

    command = @commands.get(name)
    return unless command

    command.run(message)
  rescue => e
    warn "[Rubord:Command] #{e.message}"
  end
end