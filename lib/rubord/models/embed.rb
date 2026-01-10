module Rubord
  class Embed
    attr_accessor :title,
                  :description,
                  :url,
                  :timestamp,
                  :color,
                  :footer,
                  :image,
                  :thumbnail,
                  :author,
                  :fields

    def initialize
      @fields = []
    end

    def title(text)
      @title = text
      self
    end

    def description(text)
      @description = text
      self
    end

    def url(link)
      @url = link
      self
    end

    def timestamp(time = Time.now)
      @timestamp = time.utc.iso8601
      self
    end

    def color(hex)
      @color = Rubord.Parser.color(hex)
      self
    end

    def footer(text:, icon_url: nil)
      @footer = { text: text, icon_url: icon_url }
      self
    end

    def image(url)
      @image = { url: url }
      self
    end

    def thumbnail(url)
      @thumbnail = { url: url }
      self
    end

    def author(name:, url: nil, icon_url: nil)
      @author = { name: name, url: url, icon_url: icon_url }
      self
    end

    def add_field(name, value, inline = false)
      @fields << { name: name, value: value, inline: inline }
      self
    end

    def to_h
      {
        title: @title,
        description: @description,
        url: @url,
        timestamp: @timestamp,
        color: @color,
        footer: @footer,
        image: @image,
        thumbnail: @thumbnail,
        author: @author,
        fields: @fields.empty? ? nil : @fields
      }.compact
    end
  end
  
  def self.Embed
    Embed.new
  end
end