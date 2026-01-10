module Rubord
  class Guild
    attr_reader :id,
                :members,
                :roles,
                :client

    def initialize(data, client)
      @client   = client
      @id       = data["id"]
      @members  = Rubord::Collection.new
      @roles    = Rubord::Collection.new
      @owner    = data["owner"] || false
      @owner_id = data["owner_id"]

      client.guilds.set(@id, self)
      load_roles(data["roles"]) if data["roles"]
    end

    def is_owner?(user_id)
      @owner_id.to_i == user_id.to_i
    end

    def owner_id
      @owner_id
    end

    def fetch_owner
      return nil unless @owner_id
      @client.users.get(@owner_id) ||
        begin
          data = @client.rest.get_user(@owner_id)
          user = Rubord::User.new(data)
          @client.users.set(user.id, user)
          user
        rescue Rubord::HTTPError
          nil
        end
    end

    def members_count
      @members.size
    end

    def load_roles(raw_roles)
      raw_roles.each do |role_data|
        role = Rubord::Role.new(role_data)
        @roles.set(role.id, role)
      end
    end

    def add_member(data)
      member = Rubord::Member.new(
        data.merge("guild_id" => @id),
        @client
      )

      @members.set(member.id, member)
      member
    end

    def fetch_member(user_id)
      cached = @members.get(user_id)
      return cached if cached

      data = @client.rest.get_guild_member(@id, user_id)
      return nil unless data

      add_member(data)
    rescue Rubord::HTTPError
      nil
    end

    def inspect
      "#<Rubord::Guild id=#{@id} members=#{@members.size} roles=#{@roles.size}>"
    end
  end
end