require_relative "rest"
require_relative "gateway"


module Rubord
  # Main client class for interacting with the Discord API.
  #
  # The Client serves as the primary interface for creating Discord bots
  # and managing connections to the Discord Gateway and REST API.
  #
  # @example Creating a basic bot client
  #   client = Rubord::Client.new(prefix: "!", intents: [:messages])
  #   client.login("YOUR_BOT_TOKEN")
  #
  #   client.on(:ready) do |user|
  #     puts "Logged in as #{user.username}"
  #   end
  #
  #   client.on(:message_create) do |message|
  #     if message.content.start_with?("!ping")
  #       message.reply("Pong!")
  #     end
  #   end
  #
  # @since 1.0.0
  # @see https://discord.com/developers/docs Discord Developer Documentation
  class Client
    # @return [Rubord::REST] The REST API client instance.
    attr_reader :rest
    
    # @return [Rubord::Gateway] The WebSocket gateway connection instance.
    attr_reader :gateway
    
    # @return [Rubord::Collection] Collection of cached messages.
    attr_reader :messages
    
    # @return [Rubord::Collection] Collection of cached channels.
    attr_reader :channels
    
    # @return [Integer] Bitwise value representing enabled Discord intents.
    attr_reader :intents
    
    # @return [String] Command prefix for message-based commands.
    attr_reader :prefix
    
    # @return [Rubord::User, nil] The bot user account, available after login.
    attr_reader :user
    
    # @return [Rubord::Collection] Collection of cached users.
    attr_reader :users
    
    # @return [Rubord::Collection] Collection of cached guilds (servers).
    attr_reader :guilds

    # @return [Rubord::Commands] Commands for the bot.
    attr_reader :commands

    # Initializes a new Discord client instance.
    #
    # @param prefix [String] The command prefix for message commands.
    #   Default is empty string (no prefix required).
    # @param intents [Array<Symbol, Integer>] Discord intents to enable.
    #   Can be symbols (e.g., `:guilds`, `:messages`) or integer bit values.
    #
    # @example With prefix and intents
    #   client = Rubord::Client.new(
    #     prefix: "!",
    #     intents: [:guilds, :guild_messages, :message_content]
    #   )
    #
    # @example With minimal configuration
    #   client = Rubord::Client.new
    #
    # @return [Rubord::Client] A new client instance.
    def initialize(prefix: "", intents: [])
      @token = nil
      @intents = parse_intents(intents)
      @prefix = prefix

      @rest = nil
      @gateway = nil
      @listeners = Hash.new { |h, k| h[k] = [] }

      @user = nil
      @start_time = Time.now.to_i
      @commands = Rubord::CommandRegistry.new
      
      @channels = Rubord::Collection.new
      @messages = Rubord::Collection.new
      @guilds = Rubord::Collection.new
      @users = Rubord::Collection.new
    end
    
    # Returns the current WebSocket gateway latency in milliseconds.
    #
    # @return [Integer] Gateway latency in ms, or 0 if not connected.
    #
    # @example
    #   puts "Latency: #{client.latency}ms"
    def latency
      @gateway&.latency || 0
    end

    # Returns the bot's uptime in seconds since login.
    #
    # @return [Integer] Uptime in seconds, or 0 if not logged in.
    #
    # @example
    #   puts "Bot has been running for #{client.uptime} seconds"
    def uptime
      return 0 unless @start_time
      Time.now.to_i - @start_time
    end

    # Retrieves the bot application's owner.
    #
    # This method fetches the application owner information from Discord
    # and caches it for subsequent calls.
    #
    # @return [Rubord::User, nil] The application owner user object,
    #   or nil if not logged in.
    #
    # @example
    #   owner = client.owner
    #   puts "Bot owned by: #{owner.username}"
    def owner
      return nil unless @user

      cached = @users.get(:__owner__)
      return cached if cached

      data = @rest.get_application
      owner = Rubord::User.new(data["owner"])

      @users.set(owner.id, owner)
      @users.set(:__owner__, owner)

      owner
    end

    # Authenticates and connects to the Discord API.
    #
    # This method initializes the REST client, connects to the Gateway,
    # and starts processing Discord events.
    #
    # @param token [String] The Discord bot token.
    #   Format: "Bot YOUR_TOKEN_HERE" or just "YOUR_TOKEN_HERE".
    #
    # @return [Rubord::Client] Self for method chaining.
    #
    # @raise [InvalidTokenError] If the token is nil or empty.
    #
    # @example Basic login
    #   client.login("Bot MTExODg0OTgxOTk0NzMxOTgwOA.G0L2QN.secret")
    #
    # @example With method chaining
    #   client
    #     .login(token)
    #     .on(:ready) { |user| puts "Ready!" }
    def login(token)
      raise InvalidTokenError, "Discord token cannot be empty" if token.nil? || token.strip.empty?

      @token = token
      @rest = Rubord::REST.new(token)
      @gateway = Rubord::Gateway.new(token, @intents)

      @gateway.connect do |event, data|
        handle_event(event, data)
      end

      @start_time = Time.now.to_i

      self
    end

    # Gracefully disconnects from Discord and stops the client.
    #
    # This method closes the WebSocket connection and stops
    # event processing.
    #
    # @return [void]
    #
    # @example
    #   # Handle graceful shutdown
    #   Signal.trap("INT") do
    #     puts "Shutting down..."
    #     client.stop
    #     exit
    #   end
    def stop
      @gateway&.close
    end

    def on_ready(&block)
      on(:ready, &block)
    end

    # @yieldparam message [Rubord::Message]
    def on_message(&block)
      on(:message_create, &block)
    end

    # @yieldparam interaction [Rubord::Interaction]
    def on_interaction(&block)
      on(:interaction_create, &block)
    end

    # Registers an event listener callback.
    #
    # @param event [Symbol, String] The event name to listen for.
    #   Common events: `:ready`, `:message_create`, `:guild_create`, etc.
    # @yield [*args] The block to execute when the event fires.
    #   Block arguments vary by event type.
    #
    # @return [void]
    #
    # @example Listening for ready event
    #   client.on(:ready) do |user|
    #     puts "Logged in as #{user.username}"
    #   end
    #
    # @example Listening for messages
    #   client.on(:message_create) do |message|
    #     if message.content == "ping"
    #       message.reply("pong")
    #     end
    #   end
    #
    # @see #trigger For event triggering mechanism
    def on(event, &block)
      @listeners[event.to_sym] << block
    end

    # Fetches a channel from Discord API and caches it.
    #
    # @param channel_id [String, Integer] The Discord channel ID to fetch.
    #
    # @return [Rubord::Channel] The channel object.
    #
    # @example
    #   channel = client.fetch_channel("123456789012345678")
    #   puts "Channel name: #{channel.name}"
    def fetch_channel(channel_id)
      data = @rest.get_channel(channel_id)
      channel = Rubord::Channel.new(data, self)
      @channels.set(channel.id, channel)
      channel
    end

    # Fetches a message from Discord API and caches it.
    #
    # @param channel_id [String, Integer] The ID of the channel containing the message.
    # @param message_id [String, Integer] The ID of the message to fetch.
    #
    # @return [Rubord::Message] The message object.
    #
    # @example
    #   message = client.fetch_message("123456789012345678", "987654321098765432")
    #   puts "Message content: #{message.content}"
    def fetch_message(channel_id, message_id)
      data = @rest.get_message(channel_id, message_id)
      msg = Rubord::Message.new(data, self)
      @messages.set(msg.id, msg)
      msg
    end

    private

  def process_command(message)
    return if message.author.bot
    return unless @prefix && !@prefix.empty?
    return unless message.content.start_with?(@prefix)

    input = message.content[@prefix.length..].strip
    return if input.empty?

    name, *args = input.split(/\s+/)
    name.downcase!

    command = @commands.get(name)
    return unless command

    command.run(message, args = args)
  rescue => e
    Rubord::Logger.warn "[Rubord:Command Error] #{e.class}: #{e.message}"
    Rubord::Logger.warn e.backtrace.join("\n")
  end

    # Internal event handler for gateway events.
    #
    # This method processes raw gateway events, creates appropriate
    # objects, updates caches, and triggers registered listeners.
    #
    # @param event [Symbol] The gateway event type.
    # @param data [Hash] The event data from Discord.
    #
    # @return [void]
    #
    # @see #trigger
    def handle_event(event, data)
      case event
      when :ready
        @user = Rubord::User.new(data["user"])
        @users.set(@user.id, @user)
        trigger(:ready, @user)

      when :guild_create
        guild = Rubord::Guild.new(data, self)
        @guilds.set(guild.id, guild)

        if data["members"]
          data["members"].each do |m|
            guild.add_member(m)
          end
        end

      when :guild_member_add
        guild = @guilds.get(data["guild_id"])
        guild&.add_member(data)

      when :message_create
        msg = Rubord::Message.new(data, self)
        @messages.set(msg.id, msg)

        process_command(msg)
        trigger(:message_create, msg)

      when :interaction_create
        interaction = Rubord::Interaction.new(data, self)
        trigger(:interaction_create, interaction)
      else
        trigger(event, data)
      end
    end

    # Triggers all registered listeners for an event.
    #
    # @param event [Symbol] The event to trigger.
    # @param args [Array] Arguments to pass to listeners.
    #
    # @return [void]
    #
    # @note Listeners can accept either `(client, *args)` or just `(*args)`
    #   depending on their arity.
    def trigger(event, payload)
      return unless @listeners[event]

      @listeners[event].each do |cb|
        cb.call(payload)
      end
    end

    # Parses and combines intent symbols/values into a bitwise integer.
    #
    # @param intents [Array<Symbol, Integer>] Array of intent symbols or values.
    #
    # @return [Integer] Combined bitwise intent value.
    #
    # @see Rubord::Intents.combine
    def parse_intents(intents)
      Rubord::Intents.combine(intents)
    end
  end
end