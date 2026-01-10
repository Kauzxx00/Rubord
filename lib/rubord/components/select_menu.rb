module Rubord
  class SelectMenu
    attr_accessor :type,
                  :custom_id,
                  :options,
                  :placeholder,
                  :min_values,
                  :max_values,
                  :disabled

    def initialize(custom_id:, placeholder: nil, min_values: 1, max_values: 1, disabled: false)
      @type = 3
      @custom_id = custom_id
      @options = []
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
      @disabled = disabled
    end

    def add_option(label:, value:, description: nil, emoji: nil, default: false)
      @options << {
        label: label,
        value: value,
        description: description,
        emoji: emoji,
        default: default
      }.compact
      self
    end

    def to_h
      {
        type: @type,
        custom_id: @custom_id,
        options: @options,
        placeholder: @placeholder,
        min_values: @min_values,
        max_values: @max_values,
        disabled: @disabled
      }.compact
    end
  end

  def self.SelectMenu(**args)
    SelectMenu.new(**args)
  end
end