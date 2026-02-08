require_relative "base"

module Rubord
  module Components
    class Container < BaseComponent
      attr_reader :components, :color

      def initialize(*components, color: nil)
        super(17)
        @color = Rubord.Parser.color(color)
        @components = []
        components.compact.each { |c| add(c) }
      end

      def add(component)
        unless component.respond_to?(:to_h)
          raise ArgumentError, "Invalid component inside Container: #{component.inspect}"
        end

        @components << component
        self
      end

      def to_h
        payload = {
          type: @type,
          components: @components.map(&:to_h).compact
        }

        payload[:accent_color] = @color if @color
        payload
      end
    end
  end

  def self.Container(*components, **opts)
    Components::Container.new(*components, **opts)
  end
end