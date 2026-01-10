require "net/http"
require "uri"
require "openssl"
require "json"

if ENV["TERMUX_VERSION"]
  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] =
    OpenSSL::SSL::VERIFY_PEER

  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_callback] =
    proc do |preverify_ok, ssl_ctx|
      return true if preverify_ok

      ssl_ctx.error == OpenSSL::X509::V_ERR_UNABLE_TO_GET_CRL
    end
end

module Rubord
  class REST
    BASE_URL = "https://discord.com/api/v10"

    def initialize(token)
      @token = token
    end

    def request(method, path, body: nil)
      uri = URI("#{BASE_URL}#{path}")
      req = build_request(method, uri)

      req.body = JSON.generate(body) if body

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        res = http.request(req)
        handle_response(res)
      end
    end

    def build_request(method, uri)
      klass = {
        get:    Net::HTTP::Get,
        post:   Net::HTTP::Post,
        put:    Net::HTTP::Put,
        patch:  Net::HTTP::Patch,
        delete: Net::HTTP::Delete
      }.fetch(method)

      req = klass.new(uri)
      req["Authorization"] = "Bot #{@token}"
      req["Content-Type"]  = "application/json"
      req
    end

    def handle_response(res)
      return nil if res.body.nil? || res.body.empty?

      json = JSON.parse(res.body)

      unless res.is_a?(Net::HTTPSuccess)
        raise StandardError, "HTTP #{res.code}: #{json}"
      end

      json
    end

    def send_message(channel_id, content: nil, embeds: nil, components: nil, flags: nil)
      body = build_message_body(
        content: content,
        embeds: embeds,
        components: components,
        flags: flags
      )

      request(:post, "/channels/#{channel_id}/messages", body: body)
    end

    def reply_message(channel_id, message_id, **opts)
      body = build_message_body(**opts)
      body[:message_reference] = {
        message_id: message_id,
        channel_id: channel_id
      }

      request(:post, "/channels/#{channel_id}/messages", body: body)
    end

    def get_channel(channel_id)
      request(:get, "/channels/#{channel_id}")
    end

    def get_message(channel_id, message_id)
      request(:get, "/channels/#{channel_id}/messages/#{message_id}")
    end

    def get_user(user_id)
      request(:get, "/users/#{user_id}")
    end

    def get_guild(guild_id)
      request(:get, "/guilds/#{guild_id}")
    end

    def get_guild_member(guild_id, user_id)
      request(:get, "/guilds/#{guild_id}/members/#{user_id}")
    end

    def kick_guild_member(guild_id, user_id, reason: nil)
      path = "/guilds/#{guild_id}/members/#{user_id}"
      path += "?reason=#{URI.encode(reason)}" if reason
      request(:delete, path)
    end

    def ban_guild_member(guild_id, user_id, delete_message_days: 0, reason: nil)
      path = "/guilds/#{guild_id}/bans/#{user_id}?delete_message_days=#{delete_message_days}"
      path += "&reason=#{URI.encode(reason)}" if reason
      request(:put, path)
    end

    def unban_guild_member(guild_id, user_id, reason: nil)
      path = "/guilds/#{guild_id}/bans/#{user_id}"
      path += "?reason=#{URI.encode(reason)}" if reason
      request(:delete, path)
    end

    def get_application
      request(:get, "/oauth2/applications/@me")
    end

    def interactions_response(interaction_id, interaction_token, type:, data: nil)
      body = { type: type }
      body[:data] = data if data
      request(:post, "/interactions/#{interaction_id}/#{interaction_token}/callback", body: body)
    end

    def interaction_edit(application_id, token, **opts)
      body = build_message_body(**opts)

      request(
        :patch,
        "/webhooks/#{application_id}/#{token}/messages/@original",
        body: body
      )
    end

    def build_message_body(content: nil, embeds: nil, components: nil, flags: nil)
      body = {}
      body[:content]    = content if content
      body[:embeds]     = Array(embeds).map(&:to_h) if embeds
      body[:components] = Array(components).map(&:to_h) if components
      body[:flags]      = flags if flags
      body
    end
  end
end