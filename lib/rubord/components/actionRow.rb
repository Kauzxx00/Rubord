# components/actionRow.rb

module Rubord
  # Represents a Discord action row container.
  #
  # Action rows are containers for message components (buttons, select menus).
  # They can hold up to 5 buttons or 1 select menu per row.
  #
  # @example Creating an action row with buttons
  #   row = Rubord::ActionRow.new(
  #     Rubord::Button.new(label: "Yes", custom_id: "yes"),
  #     Rubord::Button.new(label: "No", custom_id: "no")
  #   )
  #
  # @example Creating an empty row and adding components
  #   row = Rubord::ActionRow.new
  #   row.add(Rubord::Button.new(label: "Click", custom_id: "click"))
  #
  # @since 1.0.0
  # @see https://discord.com/developers/docs/interactions/message-components#action-rows
  class ActionRow
    # @return [Integer] Component type (always 1 for action rows).
    attr_accessor :type
    
    # @return [Array<Button, SelectMenu>] Components in this action row.
    attr_accessor :components

    # Creates a new action row.
    #
    # @param components [Array<Button, SelectMenu>] Components to include in the row.
    #   Can be empty.
    #
    # @example Empty action row
    #   ActionRow.new
    #
    # @example With initial buttons
    #   ActionRow.new(
    #     Button.new(label: "Save", custom_id: "save"),
    #     Button.new(label: "Cancel", custom_id: "cancel")
    #   )
    #
    # @note Action rows can contain either:
    #   - Up to 5 buttons
    #   - OR 1 select menu
    #   Not a mixture of both.
    def initialize(*components)
      @type = 1
      @components = components
    end

    # Adds a component to the action row.
    #
    # @param component [Button, SelectMenu] Component to add.
    #
    # @return [Rubord::ActionRow] Self for method chaining.
    #
    # @raise [ArgumentError] If adding component would violate Discord limits.
    #
    # @example
    #   row = ActionRow.new
    #   row.add(Button.new(label: "Test", custom_id: "test"))
    def add(component)
      @components << component
      self
    end

    # Converts the action row to a Discord API-compatible hash.
    #
    # @return [Hash] Action row data in Discord API format.
    #
    # @example
    #   row = ActionRow.new(Button.new(label: "Btn", custom_id: "btn"))
    #   row.to_h
    #   # => {type: 1, components: [{type: 2, style: 1, label: "Btn", custom_id: "btn", disabled: false}]}
    def to_h
      {
        type: @type,
        components: @components.map(&:to_h)
      }
    end
  end

  # Factory method for creating ActionRow instances.
  #
  # @param args [Array<Button, SelectMenu>] Components to include.
  # @return [Rubord::ActionRow] New action row instance.
  #
  # @example
  #   row = Rubord.ActionRow(button1, button2)
  def self.ActionRow(*args)
    ActionRow.new(*args)
  end
end