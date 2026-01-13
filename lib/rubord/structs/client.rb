require_relative "rest"
require_relative "gateway"

module Rubord
  class Client
    attr_reader :rest,
                :gateway,
                :messages,
                :channels,
                :intents,
                :prefix,
                :user,
                :users,
                :guilds

    def initialize(prefix: "", intents: [])
      @token     = nil
      @intents   = parse_intents(intents)
      @prefix    = prefix

      @rest      = nil
      @gateway   = nil
      @listeners = Hash.new { |h, k| h[k] = [] }

      @user      = nil
      @latency   = nil
      
      @channels  = Rubord::Collection.new
      @messages  = Rubord::Collection.new
      @guilds    = Rubord::Collection.new
      @users     = Rubord::Collection.new
    end

    def users
      @users
    end

    def guilds
      @guilds
    end

    def latency
      @gateway.latency
    end

    def owner
      return nil unless @user

      cached = @users.get(:__owner__)
      return cached if cached

      data = @rest.get_application
      owner = Rubord::User.new(data["owner"])

      @users.set(owner.id, owner)
      @users.set(:__owner__, owner)

      owner
    rescue Rubord::HTTPError
      nil
    end

    def login(token)
      raise InvalidTokenError, "Discord token cannot be empty" if token.nil? || token.strip.empty?

      @token = token
      @rest = Rubord::REST.new(token)
      @gateway = Rubord::Gateway.new(token, @intents)

      @gateway.connect do |event, data|
        handle_event(event, data)
      end

      self
    end

    def start
      @gateway&.join
    end

    def on(event, &block)
      @listeners[event.to_sym] << block
    end

    def fetch_channel(channel_id)
      data = @rest.get_channel(channel_id)
      channel = Rubord::Channel.new(data, self)
      @channels.set(channel.id, channel)
      channel
    end

    def fetch_message(channel_id, message_id)
      data = @rest.get_message(channel_id, message_id)
      msg = Rubord::Message.new(data, self)
      @messages.set(msg.id, msg)
      msg
    end

    private

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
        trigger(:message_create, msg)

      when :interaction_create
        interaction = Rubord::Interaction.new(data, self)
        trigger(:interaction_create, interaction)
      else
        trigger(event, data)
      end
    end

    def trigger(event, *args)
      return unless @listeners[event]

      @listeners[event].each do |cb|
        if cb.arity >= (args.size + 1) || cb.arity < 0
          cb.call(self, *args)
        else
          cb.call(*args)
        end
      end
    end

    def parse_intents(intents)
      Rubord::Intents.combine(intents)
    end
  end
end