module Rubord
  class User
    attr_reader :id,
                :username,
                :globalname,
                :discriminator, 
                :bot

    def initialize(data)
      @id             = data["id"]
      @username       = data["username"]
      @globalname     = data["global_name"]
      @discriminator  = data["discriminator"]
      @bot            = data["bot"] || false
    end

    def bot?
      @bot
    end

    def tag
      "#{@username}##{@discriminator}"
    end
  end
end
