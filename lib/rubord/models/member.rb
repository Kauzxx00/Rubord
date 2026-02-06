module Rubord
  class Member
    attr_reader :id,
                :user,
                :roles,
                :guild_id

    def initialize(data, client)
      @client   = client
      @guild_id = data["guild_id"]
      @roles    = data["roles"] || []

      @user = Rubord::User.new(data["user"])
      @id   = @user.id

      @client.users.set(@id, @user)
      guild&.members&.set(@id, self)
    end

    def guild
      @client.guilds.get(@guild_id)
    end

    def role_objects
      return [] unless guild && guild.roles

      @roles
        .map { |role_id| guild.roles.get(role_id) }
        .compact
    end

    def permissions
      return [] unless guild && guild.roles

      bitfield = 0

      if (everyone = guild.roles.get(guild.id))
        bitfield |= everyone.permissions
      end

      role_objects.each do |role|
        bitfield |= role.permissions
      end

      if (bitfield & Rubord::Permissions::FLAGS[:administrator]) != 0
        return Rubord::Permissions::FLAGS.keys
      end

      Rubord::Permissions::FLAGS
        .select { |_name, flag| (bitfield & flag) != 0 }
        .keys
    end

    def has_permission?(perm)
      permissions.include?(perm.to_sym)
    end

    def inspect
      "#<Rubord::Member id=#{@id} guild_id=#{@guild_id} roles=#{@roles}>"
    end
  end
end