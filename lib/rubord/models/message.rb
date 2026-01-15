module Rubord
  class Message
    attr_reader :id,
                :content,
                :author,
                :channel_id,
                :guild_id,
                :channel,
                :mentions

    def initialize(data, client)
      @client     = client
      @id         = data["id"]
      @content    = data["content"]
      @channel_id = data["channel_id"]
      @guild_id   = data["guild_id"]

      @author = Rubord::User.new(data["author"])
      client.users.set(@author.id, @author)

      @channel =
        client.channels.get(@channel_id) ||
        Rubord::Channel.new({ "id" => @channel_id }, client)

      @mentions = Rubord::Mention.new(
        data,
        client,
        guild
      )
    end

    def guild
      return nil unless @guild_id

      @guild ||=
        @client.guilds.get(@guild_id) ||
        Rubord::Guild.new(@client.rest.get_guild(@guild_id), @client)
    end

    def member
      return nil unless guild
      guild.fetch_member(@author.id)
    end

    def post(content = nil, embeds: nil, components: nil, flags: nil)
      @client.rest.send_message(
        @channel_id,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def reply(content = nil, embeds: nil, components: nil, flags: nil)
      @client.rest.reply_message(
        @channel_id,
        @id,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def edit(content = nil, embeds: nil, components: nil, flags: nil)
      @client.rest.edit_message(
        @channel_id,
        @id,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def delete
      @client.rest.delete_message(
        @channel_id,
        @id
      )
    end

    def inspect
      "#<Rubord::Message id=#{@id} mentions=#{mentions.inspect}>"
    end
  end
end