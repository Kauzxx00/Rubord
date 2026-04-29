require_relative "base"

module Rubord
  module Components
    class Section < BaseComponent
      def initialize(components:, accessory: nil)
        super(9)
        @components = components
        @accessory = accessory
      end

      def to_h
        h = {
          type: @type,
          components: @components.map(&:to_h).compact
        }

        h[:accessory] = @accessory.to_h if @accessory
        h
      end
    end
  end

  def self.Section(**args)
    Components::Section.new(**args)
  end
end