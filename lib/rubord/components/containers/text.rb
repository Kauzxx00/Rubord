require_relative "base"

module Rubord
  module Components
    class Text < BaseComponent
      def initialize(*content)
        super(10)
        @content = content
      end

      def to_h
        {
          type: @type,
          content: @content.join("\n")
        }
      end
    end
  end

  def self.Text(*content)
    Components::Text.new(content)
  end
end