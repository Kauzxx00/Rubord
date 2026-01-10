module Rubord
  class Modal
    attr_accessor :type,
                  :custom_id,
                  :title,
                  :components

    def initialize(custom_id:, title:)
      @type = 1
      @custom_id = custom_id
      @title = title
      @components = []
    end

    def add_text_input(custom_id:, label:, style: 1, min_length: nil, max_length: nil, required: true, value: nil, placeholder: nil)
      @components << {
        type: 4,
        custom_id: custom_id,
        style: style,
        label: label,
        min_length: min_length,
        max_length: max_length,
        required: required,
        value: value,
        placeholder: placeholder
      }.compact
      self
    end

    def to_h
      {
        type: @type,
        custom_id: @custom_id,
        title: @title,
        components: [
          {
            type: 1,
            components: @components
          }
        ]
      }
    end
  end

  def self.Modal(**args)
    Modal.new(**args)
  end
end