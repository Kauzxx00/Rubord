# components/button.rb

module Rubord
  # Represents a Discord interactive button component.
  #
  # Buttons are interactive elements that users can click to trigger actions.
  # They can be used in messages, modals, and action rows.
  #
  # @example Creating a primary button
  #   button = Rubord::Button.new(
  #     label: "Click Me",
  #     style: 1,
  #     custom_id: "my_button"
  #   )
  #
  # @example Creating a link button
  #   link_button = Rubord::Button.new(
  #     label: "Visit Website",
  #     style: 5,
  #     url: "https://example.com"
  #   )
  #
  # @since 1.0.0
  # @see https://discord.com/developers/docs/interactions/message-components#buttons
  class Button
    # @return [Integer] Component type (always 2 for buttons).
    attr_accessor :type
    
    # @return [Integer] Button style (1-5).
    #   - 1: Primary (blurple)
    #   - 2: Secondary (grey)
    #   - 3: Success (green)
    #   - 4: Danger (red)
    #   - 5: Link (grey, navigates to URL)
    attr_accessor :style
    
    # @return [String] Text displayed on the button (max 80 characters).
    attr_accessor :label
    
    # @return [String, nil] Developer-defined identifier for the button.
    #   Required for non-link buttons, must be unique per message.
    attr_accessor :custom_id
    
    # @return [String, nil] URL for link buttons (style 5).
    attr_accessor :url
    
    # @return [Boolean] Whether the button is disabled.
    attr_accessor :disabled
    
    # @return [Hash, nil] Emoji to display on the button.
    #   Format: `{name: "emoji_name", id: "emoji_id", animated: false}`
    attr_accessor :emoji

    # Creates a new button component.
    #
    # @param label [String] Text label displayed on the button.
    # @param style [Integer] Button style (1-5).
    #   Defaults to 1 (primary).
    # @param custom_id [String, nil] Developer-defined identifier.
    #   Required for non-link buttons.
    # @param url [String, nil] URL for link buttons (style 5).
    # @param disabled [Boolean] Whether the button is disabled.
    #   Defaults to false.
    # @param emoji [Hash, nil] Emoji to display on the button.
    #
    # @raise [ArgumentError] If required parameters are missing.
    #
    # @example Primary button with emoji
    #   Button.new(
    #     label: "Submit",
    #     style: 1,
    #     custom_id: "submit_btn",
    #     emoji: { name: "✅" }
    #   )
    #
    # @example Disabled danger button
    #   Button.new(
    #     label: "Delete",
    #     style: 4,
    #     custom_id: "delete_btn",
    #     disabled: true
    #   )
    def initialize(label:, style: 1, custom_id: nil, url: nil, disabled: false, emoji: nil)
      @type = 2
      @style = style
      @label = label
      @custom_id = custom_id
      @url = url
      @disabled = disabled
      @emoji = emoji
    end

    # Converts the button to a Discord API-compatible hash.
    #
    # @return [Hash] Button data in Discord API format.
    #
    # @example
    #   button = Button.new(label: "Test", custom_id: "test")
    #   button.to_h
    #   # => {type: 2, style: 1, label: "Test", custom_id: "test", disabled: false}
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

  # Factory method for creating Button instances.
  #
  # @param args [Hash] Button initialization parameters.
  # @return [Rubord::Button] New button instance.
  #
  # @example
  #   button = Rubord.Button(label: "Click", custom_id: "click")
  def self.Button(label:, style: 1, custom_id: nil, url: nil, disabled: false, emoji: nil)
    Button.new(
      label: label,
      style: style,
      custom_id: custom_id,
      url: url,
      disabled: disabled,
      emoji: emoji
    )
  end
end