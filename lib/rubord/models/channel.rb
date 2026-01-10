module Rubord
  class Channel
    attr_reader :id,
                :name,
                :type,
                :client

    def initialize(data, client)
      @id     = data["id"]
      @name   = data["name"]
      @type   = data["type"]
      @client = client

      client&.channels&.set(@id, self)
    end

    def send(content = nil, embeds: nil, components: nil, flags: nil)
      ensure_client!

      client.rest.send_message(
        @id,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def fetch_message(message_id)
      client.rest.get_message(@id, message_id)
    end

    def guild
      return nil unless client && client.respond_to?(:guilds)
      client.guilds.get(guild_id)
    end

    def text?
      type == 0
    end

    def voice?
      type == 2
    end

    def inspect
      "#<Rubord::Channel id=#{id} name=#{name.inspect} type=#{type}>"
    end
  end
end