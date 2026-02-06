module Rubord
  class Emoji
    attr_reader :id,
                :name,
                :roles,
                :user,
                :require_colons,
                :managed,
                :animated,
                :available

    def initialize(data, client)
      @client        = client
      @id            = data["id"]
      @name          = data["name"]
      @roles         = data["roles"] || []
      @require_colons = data["require_colons"]
      @managed       = data["managed"]
      @animated      = data["animated"]
      @available     = data.fetch("available", true)

      if data["user"]
        @user = Rubord::User.new(data["user"])
        client.users.set(@user.id, @user)
      end
    end

    def to_discord
      if animated
        "<a:#{@name}:#{@id}>"
      else
        "<:#{@name}:#{@id}>"
      end
    end

    def to_h
      {
        id: @id,
        name: @name,
        roles: @roles,
        format: to_discord,
        user: @user ? @user.to_h : nil,
        require_colons: @require_colons,
        managed: @managed,
        animated: @animated,
        available: @available
      }
    end

    def inspect
      "#<Rubord::Emoji name=#{@name} id=#{@id}"
    end
  end
end