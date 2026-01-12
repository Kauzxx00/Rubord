require_relative "base"

module Rubord
  module Components
    class Separator < BaseComponent
      SPACING = {
        small: 1,
        large: 2
      }.freeze

      attr_reader :divider, :spacing

      def initialize(divider: true, spacing: :small)
        super(14)

        @divider = !!divider
        @spacing = parse_spacing(spacing)
      end

      def to_h
        {
          type: @type,
          divider: @divider,
          spacing: @spacing
        }
      end

      private

      def parse_spacing(value)
        case value
        when Integer
          unless SPACING.value?(value)
            raise ArgumentError, "Invalid spacing value: #{value}"
          end
          value
        when Symbol, String
          spacing = SPACING[value.to_sym]
          raise ArgumentError, "Invalid spacing: #{value.inspect}" unless spacing
          spacing
        else
          raise ArgumentError, "Invalid spacing type: #{value.class}"
        end
      end
    end
  end

  def self.Separator(**opts)
    Components::Separator.new(**opts)
  end
end