module Rubord
  class Role
    attr_reader :id,
                :name,
                :permissions,
                :position

    def initialize(data)
      @id           = data["id"]
      @name         = data["name"]
      @permissions  = data["permissions"].to_i
      @position     = data["position"]
    end
  end
end