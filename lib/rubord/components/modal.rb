# components/modal.rb

module Rubord
  # Represents a Discord modal dialog component.
  #
  # Modals are pop-up dialog windows that can contain text inputs.
  # They're triggered by interactions and allow for more complex user input.
  #
  # @example Creating a simple modal
  #   modal = Rubord::Modal.new(
  #     custom_id: "feedback_form",
  #     title: "Submit Feedback"
  #   )
  #   modal.add_text_input(
  #     custom_id: "feedback",
  #     label: "Your feedback",
  #     style: 2,
  #     placeholder: "Type your feedback here..."
  #   )
  #
  # @since 1.0.0
  # @see https://discord.com/developers/docs/interactions/modals
  class Modal
    # @return [Integer] Component type (always 1 for modals).
    attr_accessor :type
    
    # @return [String] Developer-defined identifier.
    attr_accessor :custom_id
    
    # @return [String] Modal title (max 45 characters).
    attr_accessor :title
    
    # @return [Array<Hash>] List of text input components.
    attr_accessor :components

    # Creates a new modal dialog.
    #
    # @param custom_id [String] Developer-defined identifier.
    # @param title [String] Modal title (max 45 characters).
    #
    # @example
    #   Modal.new(
    #     custom_id: "user_registration",
    #     title: "Register Account"
    #   )
    def initialize(custom_id:, title:)
      @type = 1
      @custom_id = custom_id
      @title = title
      @components = []
    end

    # Adds a text input field to the modal.
    #
    # @param custom_id [String] Developer-defined identifier for the input.
    # @param label [String] Label displayed above the input (max 45 characters).
    # @param style [Integer] Input style (1=single-line, 2=multi-line).
    #   Defaults to 1.
    # @param min_length [Integer, nil] Minimum input length.
    # @param max_length [Integer, nil] Maximum input length.
    # @param required [Boolean] Whether the input is required.
    #   Defaults to true.
    # @param value [String, nil] Pre-filled value.
    # @param placeholder [String, nil] Placeholder text.
    #
    # @return [Rubord::Modal] Self for method chaining.
    #
    # @example Single-line required input
    #   modal.add_text_input(
    #     custom_id: "username",
    #     label: "Username",
    #     required: true,
    #     min_length: 3,
    #     max_length: 20
    #   )
    #
    # @example Multi-line optional input
    #   modal.add_text_input(
    #     custom_id: "bio",
    #     label: "Biography",
    #     style: 2,
    #     required: false,
    #     placeholder: "Tell us about yourself...",
    #     max_length: 500
    #   )
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

    # Converts the modal to a Discord API-compatible hash.
    #
    # @return [Hash] Modal data in Discord API format.
    #
    # @example
    #   modal = Modal.new(custom_id: "test", title: "Test Modal")
    #   modal.to_h
    #   # => {type: 1, custom_id: "test", title: "Test Modal", components: [{type: 1, components: []}]}
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

  # Factory method for creating Modal instances.
  #
  # @param args [Hash] Modal initialization parameters.
  # @return [Rubord::Modal] New modal instance.
  #
  # @example
  #   modal = Rubord.Modal(custom_id: "form", title: "Feedback Form")
  def self.Modal(**args)
    Modal.new(**args)
  end
end