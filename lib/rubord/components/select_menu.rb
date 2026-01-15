# components/select_menu.rb

module Rubord
  # Represents a Discord select menu component.
  #
  # Select menus are dropdown components that allow users to select
  # one or multiple options from a list.
  #
  # @example Creating a single-select menu
  #   menu = Rubord::SelectMenu.new(
  #     custom_id: "game_selection",
  #     placeholder: "Choose a game..."
  #   )
  #   menu.add_option(label: "Minecraft", value: "minecraft")
  #   menu.add_option(label: "Terraria", value: "terraria")
  #
  # @example Creating a multi-select menu
  #   menu = Rubord::SelectMenu.new(
  #     custom_id: "hobbies",
  #     placeholder: "Select your hobbies",
  #     min_values: 1,
  #     max_values: 3
  #   )
  #
  # @since 1.0.0
  # @see https://discord.com/developers/docs/interactions/message-components#select-menus
  class SelectMenu
    # @return [Integer] Component type (always 3 for select menus).
    attr_accessor :type
    
    # @return [String] Developer-defined identifier.
    attr_accessor :custom_id
    
    # @return [Array<Hash>] List of available options.
    attr_accessor :options
    
    # @return [String, nil] Placeholder text displayed when no option is selected.
    attr_accessor :placeholder
    
    # @return [Integer] Minimum number of options that must be selected.
    #   Defaults to 1.
    attr_accessor :min_values
    
    # @return [Integer] Maximum number of options that can be selected.
    #   Defaults to 1.
    attr_accessor :max_values
    
    # @return [Boolean] Whether the select menu is disabled.
    attr_accessor :disabled

    # Creates a new select menu component.
    #
    # @param custom_id [String] Developer-defined identifier.
    # @param placeholder [String, nil] Placeholder text.
    # @param min_values [Integer] Minimum selectable options.
    #   Defaults to 1.
    # @param max_values [Integer] Maximum selectable options.
    #   Defaults to 1.
    # @param disabled [Boolean] Whether the menu is disabled.
    #   Defaults to false.
    #
    # @example Basic select menu
    #   SelectMenu.new(
    #     custom_id: "color_picker",
    #     placeholder: "Choose a color",
    #     min_values: 1,
    #     max_values: 1
    #   )
    #
    # @example Multi-select menu
    #   SelectMenu.new(
    #     custom_id: "tags",
    #     placeholder: "Select up to 3 tags",
    #     min_values: 0,
    #     max_values: 3
    #   )
    def initialize(custom_id:, placeholder: nil, min_values: 1, max_values: 1, disabled: false)
      @type = 3
      @custom_id = custom_id
      @options = []
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
      @disabled = disabled
    end

    # Adds an option to the select menu.
    #
    # @param label [String] The user-facing name of the option (max 100 chars).
    # @param value [String] The developer-defined value of the option (max 100 chars).
    # @param description [String, nil] Additional description (max 100 chars).
    # @param emoji [Hash, nil] Emoji to display with the option.
    # @param default [Boolean] Whether this option is selected by default.
    #   Defaults to false.
    #
    # @return [Rubord::SelectMenu] Self for method chaining.
    #
    # @example Adding an option with description
    #   menu.add_option(
    #     label: "Ruby",
    #     value: "ruby_lang",
    #     description: "Dynamic, object-oriented programming language",
    #     emoji: { name: "💎" }
    #   )
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

    # Converts the select menu to a Discord API-compatible hash.
    #
    # @return [Hash] Select menu data in Discord API format.
    #
    # @example
    #   menu = SelectMenu.new(custom_id: "test")
    #   menu.to_h
    #   # => {type: 3, custom_id: "test", options: [], min_values: 1, max_values: 1, disabled: false}
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

  # Factory method for creating SelectMenu instances.
  #
  # @param args [Hash] Select menu initialization parameters.
  # @return [Rubord::SelectMenu] New select menu instance.
  #
  # @example
  #   menu = Rubord.SelectMenu(custom_id: "choices", placeholder: "Make a choice")
  def self.SelectMenu(**args)
    SelectMenu.new(**args)
  end
end