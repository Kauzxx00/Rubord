module Rubord
  class Mention
    attr_reader :users,
                :roles,
                :channels,
                :everyone

    def initialize(data, client, guild)
      @everyone = data["mention_everyone"] || false

      @users = (data["mentions"] || []).map do |user_data|
        user = Rubord::User.new(user_data)
        client.users.set(user.id, user)
        user
      end

      @roles = (data["mention_roles"] || []).map do |role_id|
        guild&.roles&.get(role_id)
      end

      @channels = 
        if data["mention_channels"]
          data["mention_channels"].map do |channel_data|
            channel = Rubord::Channel.new(channel_data, client)
            client.channels.set(channel.id, channel)
            channel
          end
        else
          Rubord.Parser.channel_mention(data["content"] || "").map do |channel_id|
            client.channels.get(channel_id) || Rubord::Channel.new({ "id" => channel_id }, client)
          end
        end
    end

    def mention_everyone?
      @everyone
    end

    def empty?
      users.empty? && roles.empty? && channels.empty? && !everyone
    end

    def inspect
      "#<Rubord::Mention users=#{users.size} roles=#{roles.size} channels=#{channels.size} everyone=#{everyone}>"
    end
  end
end