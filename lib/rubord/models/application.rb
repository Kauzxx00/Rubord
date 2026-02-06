module Rubord
  class Application
    attr_reader :id,
                :name,
                :icon,
                :description,
                :owner,
                :emojis
    def initialize(data, client)
      @client      = client
      @id          = data["id"]
      @name        = data["name"]
      @icon        = data["icon"]
      @description = data["description"]

      @owner = Rubord::User.new(data["owner"])
      client.users.set(@owner.id, @owner)

      @emojis = []
      fetched_emojis = client.rest.get_application_emojis(@id)["items"] || []
      fetched_emojis.each do |emoji_data|
        @emojis << Rubord::Emoji.new(emoji_data, client)
      end
    end

    def inspect
      "#<Rubord::Application id=#{@id}"
    end
  end
end