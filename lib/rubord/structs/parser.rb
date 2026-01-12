# frozen_string_literal: true

COLORS = {
  red:        "#ED4245",
  orange:     "#FEE75C",
  yellow:     "#F1C40F",
  green:      "#57F287",
  teal:       "#1ABC9C",
  blue:       "#3498DB",
  blurple:    "#5865F2",
  purple:     "#9B59B6",
  pink:       "#EB459E",
  white:      "#FFFFFF",
  gray:       "#95A5A6",
  dark_gray:  "#2C2F33",
  black:      "#000000"
}.freeze

module Rubord
  class Parser
    CHANNEL_MENTION_REGEX = /<#(\d{17,22})>/.freeze

    def timestamp(value)
      return value if value.is_a?(Time)
      return nil unless value

      Time.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def color(value)
      return nil if value.nil?

      case value
      when Symbol
        hex_to_int(COLORS[value])
      when String
        if COLORS.key?(value.to_sym)
          hex_to_int(COLORS[value.to_sym])
        else
          hex_to_int(value)
        end
      else
        value.to_i
      end
    end

    def channel_mentions(text)
      return [] unless text

      text.scan(CHANNEL_MENTION_REGEX).flatten.map(&:to_i)
    end

    private

    def hex_to_int(hex)
      return nil unless hex

      hex = hex.delete_prefix("#")
      hex.to_i(16)
    end
  end

  def self.Parser
    @parser ||= Parser.new
  end
end