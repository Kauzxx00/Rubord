module Rubord
  class User
    attr_reader :id,
                :username,
                :globalname,
                :discriminator,
                :creationDate,
                :bot,
                :tag

    def initialize(data)
      @id             = data["id"]
      @username       = data["username"]
      @globalname     = data["global_name"]
      @discriminator  = data["discriminator"]
      @creationDate   = ((@id.to_i >> 22) + 1420070400000) / 1000
      @bot            = data["bot"] || false
      @tag            = "#{@username}##{@discriminator}"
    end
  end
end
