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
    }
  end
end