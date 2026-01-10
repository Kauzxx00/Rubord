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
      @guild_id       = data["guild_id"]
      @channel_id     = data["channel_id"]
      @token          = data["token"]
      @version        = data["version"]
      @message        = if data["message"]
                          Rubord::Message.new(data["message"], client)
                        end

      member_data             = data["member"]
      member_data["guild_id"] = data["guild_id"]
      @member                 = Rubord::Member.new(member_data, client)
    end

    def reply(content = nil, embeds: nil, components: nil, ephemeral: false)
      data = {}
      data[:content] = content if content
      data[:embeds] = Array(embeds).map(&:to_h) if embeds
      data[:components] = Array(components).map(&:to_h) if components
      data[:flags] = 64 if ephemeral

      client.rest.interactions_response(
        @id,
        @token,
        type: 4,
        data: data
      )
    end

    def edit(content = nil, embeds: nil, components: nil, ephemeral: false)
      client.rest.interaction_edit(
        @application_id,
        @token,
        content: content,
        embeds: embeds,
        components: components,
        flags: ephemeral ? 64 : nil
      )
    end

    def defer(ephemeral: false)
      data = {}
      data[:flags] = 64 if ephemeral

      client.rest.interactions_response(
        @id,
        @token,
        type: 5,
        data: data
      )
    end

    def defer_update
      client.rest.interactions_response(
        @id,
        @token,
        type: 6
      )
    end

    def update(content = nil, embeds: nil, components: nil)
      client.rest.interactions_response(
        @id,
        @token,
        type: 6
      )

      client.rest.interaction_edit(
        @application_id,
        @token,
        content: content,
        embeds: embeds,
        components: components
      )
    end

    def command?
      @type == TYPES[:application_command]
    end

    def component?
      @type == TYPES[:message_component]
    end

    def is_a?(type)
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