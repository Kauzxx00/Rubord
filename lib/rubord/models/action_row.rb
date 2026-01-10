require_relative "../components/button"
require_relative "../components/select_menu"
require_relative "../components/modal"

module Rubord
  class ActionRow
    attr_accessor :type,
                  :components

    def initialize(*components)
      @type = 1
      @components = components
    end

    def add(component)
      @components << component
      self
    end

    def to_h
      {
        type: @type,
        components: @components.map(&:to_h)
      }
    end
  end

  def self.ActionRow(*args)
    ActionRow.new(*args)
  end
end