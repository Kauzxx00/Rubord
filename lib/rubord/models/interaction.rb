module Rubord
  class Interaction
    TYPES = {
      ping: 1,
      application_command: 2,
      message_component: 3,
      modal_submit: 5
    }
  
    COMPONENT_TYPES = {
      button: 2,
      select_menu: 3
    }

    attr_reader :id,
                :application_id,
                :type,
                :data,
                :values,
                :guild_id,
                :channel_id,
                :member,
                :user,
                :token,
                :version,
                :message,
                :client

    def initialize(data, client)
      @client         = client
      @id             = data["id"]
      @application_id = data["application_id"]
      @type           = data["type"]
      @data           = data["data"] || {}
      @values         = data["data"] ? data["data"]["values"] : nil
      @guild_id       = data["guild_id"]
      @channel_id     = data["channel_id"]
      @token          = data["token"]
      @version        = data["version"]

      @message        = Rubord::Message.new(data["message"], client) if data["message"]

      user_data       = data["user"] || data.dig("member", "user")
      @user           = Rubord::User.new(user_data) if user_data

      if (member = data["member"])
        member["guild_id"] = @guild_id
        @member = Rubord::Member.new(member, client)
      end
    end

    def reply(content = nil, embeds: nil, components: nil, flags: nil)
      client.rest.interactions_response(
        @id,
        @token,
        type: 4,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def edit(content = nil, embeds: nil, components: nil, flags: nil)
      client.rest.interaction_edit(
        @application_id,
        @token,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def update(content = nil, embeds: nil, components: nil, flags: nil)
      client.rest.interactions_response(
        @id,
        @token,
        type: 7,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def followUp(content = nil, embeds: nil, components: nil, flags: nil)
      client.rest.interaction_followup(
        @application_id,
        @token,
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )
    end

    def defer(ephemeral: false)
      client.rest.interactions_response(
        @id,
        @token,
        type: 5,
        flags: ephemeral ? { flags: 64 } : nil
      )
    end

    def deferUpdate
      client.rest.interactions_response(
        @id,
        @token,
        type: 6
      )
    end

    def command?
      @type == TYPES[:application_command]
    end

    def component?
      @type == TYPES[:message_component]
    end

    def is_type?(type)
      component? && @data["component_type"] == COMPONENT_TYPES[type.to_sym]
    end

    def custom_id
      @data["custom_id"]
    end

    def inspect
      "#<Rubord::Interaction id=#{@id} type=#{@type} guild_id=#{@guild_id} channel_id=#{@channel_id}>"
    end
  end
end