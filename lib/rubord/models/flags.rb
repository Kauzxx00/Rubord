module Rubord
  module Permissions
    FLAGS = {
      create_instant_invite:      1 << 0,
      kick_members:               1 << 1,
      ban_members:                1 << 2,
      administrator:              1 << 3,
      manage_channels:            1 << 4,
      manage_guild:               1 << 5,
      add_reactions:              1 << 6,
      view_audit_log:             1 << 7,
      priority_speaker:           1 << 8,
      stream:                     1 << 9,
      view_channel:               1 << 10,
      send_messages:              1 << 11,
      send_tts_messages:          1 << 12,
      manage_messages:            1 << 13,
      embed_links:                1 << 14,
      attach_files:               1 << 15,
      read_message_history:       1 << 16,
      mention_everyone:           1 << 17,
      use_external_emojis:        1 << 18,
      view_guild_insights:        1 << 19,
      connect:                    1 << 20,
      speak:                      1 << 21,
      mute_members:               1 << 22,
      deafen_members:             1 << 23,
      move_members:               1 << 24,
      use_vad:                    1 << 25,
      change_nickname:            1 << 26,
      manage_nicknames:           1 << 27,
      manage_roles:               1 << 28,
      manage_webhooks:            1 << 29,
      manage_emojis_and_stickers: 1 << 30,
      use_application_commands:   1 << 31,
      manage_events:              1 << 32,
      moderate_members:           1 << 40
    }.freeze

    ALL = FLAGS.values.reduce(0, :|)

    def self.combine(*perms)
      perms.map { |p| FLAGS[p] }.compact.reduce(0, :|)
    end
  end

  module Intents
    FLAGS = {
      guilds:                        1 << 0,
      guild_members:                 1 << 1,
      guild_bans:                    1 << 2,
      guild_emojis:                  1 << 3,
      guild_integrations:            1 << 4,
      guild_webhooks:                1 << 5,
      guild_invites:                 1 << 6,
      guild_voice_states:            1 << 7,
      guild_presences:               1 << 8,
      guild_messages:                1 << 9,
      guild_message_reactions:       1 << 10,
      guild_message_typing:          1 << 11,
      direct_messages:               1 << 12,
      direct_message_reactions:      1 << 13,
      direct_message_typing:         1 << 14,
      message_content:               1 << 15,
      guild_scheduled_events:        1 << 16,
      auto_moderation_configuration: 1 << 20,
      auto_moderation_execution:     1 << 21
    }.freeze

    

    class << self
      def [](intent_name)
        FLAGS[intent_name.to_sym] if intent_name
      end

      def all = FLAGS.values.reduce(0, :|);

      def exists?(intent_name)
        FLAGS.key?(intent_name.to_sym)
      end

      def names
        FLAGS.keys
      end

      def values
        FLAGS.values
      end

      def combine(*intents)
        intents.flatten.reduce(0) do |sum, intent|
          case intent
          when Integer
            sum | intent
          when Symbol, String
            value = FLAGS[intent.to_sym]
            unless value
              warn "[Rubord:Intents] Unknown intent: #{intent.inspect}"
              next sum
            end
            sum | value
          else
            warn "[Rubord:Intents] Invalid intent type: #{intent.class}"
            sum
          end
        end
      end

      def guilds
        FLAGS[:guilds]
      end

      def guild_members
        FLAGS[:guild_members]
      end

      def guild_bans
        FLAGS[:guild_bans]
      end

      def guild_emojis
        FLAGS[:guild_emojis]
      end

      def guild_integrations
        FLAGS[:guild_integrations]
      end

      def guild_webhooks
        FLAGS[:guild_webhooks]
      end

      def guild_invites
        FLAGS[:guild_invites]
      end

      def guild_voice_states
        FLAGS[:guild_voice_states]
      end

      def guild_presences
        FLAGS[:guild_presences]
      end

      def guild_messages
        FLAGS[:guild_messages]
      end

      def guild_message_reactions
        FLAGS[:guild_message_reactions]
      end

      def guild_message_typing
        FLAGS[:guild_message_typing]
      end

      def direct_messages
        FLAGS[:direct_messages]
      end

      def direct_message_reactions
        FLAGS[:direct_message_reactions]
      end

      def direct_message_typing
        FLAGS[:direct_message_typing]
      end

      def message_content
        FLAGS[:message_content]
      end

      def guild_scheduled_events
        FLAGS[:guild_scheduled_events]
      end

      def auto_moderation_configuration
        FLAGS[:auto_moderation_configuration]
      end

      def auto_moderation_execution
        FLAGS[:auto_moderation_execution]
      end

      def default
        combine(
          :guilds,
          :guild_members,
          :guild_messages,
          :guild_message_reactions,
          :direct_messages,
          :direct_message_reactions
        )
      end

      def privileged
        combine(
          :guild_members,
          :guild_presences,
          :message_content
        )
      end

      def include?(intent_value, intent_name)
        intent_value & self[intent_name] != 0
      end

      def method_missing(name, *args)
        if FLAGS.key?(name)
          FLAGS[name]
        elsif name.to_s.end_with?('?') && FLAGS.key?(name.to_s[0...-1].to_sym)
          intent_name = name.to_s[0...-1].to_sym
          if args.first.is_a?(Integer)
            args.first & FLAGS[intent_name] != 0
          else
            super
          end
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        FLAGS.key?(name) || 
        (name.to_s.end_with?('?') && FLAGS.key?(name.to_s[0...-1].to_sym)) ||
        super
      end
    end
  end

  module MessageFlags
    FLAGS = {
      crossposted:            1 << 0,
      is_crosspost:           1 << 1,
      suppress_embeds:        1 << 2,
      source_message_deleted: 1 << 3,
      urgent:                 1 << 4,
      ephemeral:              1 << 6,
      loading:                1 << 7,
      components_v2:          1 << 15
    }.freeze

    def self.combine(*flags)
      flags.map { |f| FLAGS[f] }.compact.reduce(0, :|)
    end

    EPHEMERAL     = FLAGS[:ephemeral]
    COMPONENTS_V2 = FLAGS[:components_v2]
  end
end