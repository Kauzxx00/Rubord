module Rubord
  class Button
    attr_accessor :type,
                  :style,
                  :label,
                  :custom_id,
                  :url,
                  :disabled,
                  :emoji

    # style: 1=primary, 2=secondary, 3=success, 4=danger, 5=link
    def initialize(label:, style: 1, custom_id: nil, url: nil, disabled: false, emoji: nil)
      @type = 2
      @style = style
      @label = label
      @custom_id = custom_id
      @url = url
      @disabled = disabled
      @emoji = emoji
    end

    def to_h
      h = {
        type: @type,
        style: @style,
        label: @label,
        disabled: @disabled
      }
      h[:custom_id] = @custom_id if @custom_id
      h[:url] = @url if @url
      h[:emoji] = @emoji if @emoji
      h
    end
  end

  def self.Button(**args)
    Button.new(**args)
  end
end