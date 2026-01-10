module Rubord
  class Parser
    def timestamp(timestamp)
      Time.parse(timestamp) if timestamp
    end

    def color(color)
      return nil unless color

      if color.is_a?(String)
        color.start_with?("#") ? color[1..-1].to_i(16) : color.to_i(16)
      else
        color.to_i
      end
    end

    def channel_mention(mention)
      mention.scan(/<#(\d{17,22})>/m).flat_map { |m| m }.map(&:to_i)
    end
  end

  def self.Parser
    Parser.new
  end
end
