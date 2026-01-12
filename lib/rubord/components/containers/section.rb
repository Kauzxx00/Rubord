require_relative "base"

module Rubord
  module Components
    class Section < BaseComponent
      def initialize(text:, accessory: nil)
        super(9)
        @text = text
        @accessory = accessory
      end

      def to_h
        h = {
          type: @type,
          text: @text.is_a?(String) ? { type: 10, content: @text } : @text.to_h
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