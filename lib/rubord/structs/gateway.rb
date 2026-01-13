require "websocket-client-simple"
require "json"

module Rubord
  class Gateway
    GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"

    attr_reader :latency

    def initialize(token, intents)
      @token     = token
      @intents   = intents
      @seq       = nil
      @ws        = nil
      @stopping  = false

      @heartbeat_interval = nil
      @last_heartbeat_at  = nil
      @latency            = 0
    end

    def connect(&block)
      if @token.nil? || @token.strip.empty?
        raise InvalidTokenError, "Discord token cannot be empty"
      end
      gateway = self

      begin
        @ws = WebSocket::Client::Simple.connect(GATEWAY_URL)
      rescue => e
        raise GatewayError, "[Rubord:Gateway] Failed to connect to Discord Gateway: #{e.message}"
      end

      @ws.on(:open) do
        @latency ||= 0
      end

      @ws.on(:message) do |event|
        data = event.data

        begin
          payload = JSON.parse(data)
        rescue JSON::ParserError
          warn "[Rubord:Gateway] Received invalid JSON payload"
          next
        end

        begin
          op = payload["op"]
          t  = payload["t"]
          d  = payload["d"]
          @seq = payload["s"] if payload["s"]

          case op
          when 10
            @heartbeat_interval = d["heartbeat_interval"].to_f / 1000
            gateway.start_heartbeat
            gateway.identify

          when 11
            if @last_heartbeat_at
              @latency = ((Time.now - @last_heartbeat_at) * 1000).round
            end

          when 7
            warn "[Rubord:Gateway] Discord requested reconnect"
            gateway.reconnect
            return

          when 9
            warn "[Rubord:Gateway] Invalid session, re-identifying"
            sleep rand(1..5)
            gateway.identify
            return
          end

          if block
            case t
            when "READY"
              block.call(:ready, d)
            when "MESSAGE_CREATE"
              block.call(:message_create, d)
            when "GUILD_CREATE"
              block.call(:guild_create, d)
            when "GUILD_DELETE"
              block.call(:guild_delete, d)
            when "CHANNEL_CREATE"
              block.call(:channel_create, d)
            when "CHANNEL_DELETE"
              block.call(:channel_delete, d)
            when "MESSAGE_UPDATE"
              block.call(:message_update, d)
            when "MESSAGE_DELETE"
              block.call(:message_delete, d)
            when "INTERACTION_CREATE"
              block.call(:interaction_create, d)
            else
            end
          end

        rescue => e
          warn "[Rubord:Gateway] Error while processing event: #{e.message}"
        end
      end

      @ws.on(:close) do |_|
        warn "[Rubord:Gateway] Gateway connection closed"
        @heartbeat_thread&.kill rescue nil
        reconnect unless @stopping
      end

      @ws.on(:error) do |e|
        warn "[Rubord:Gateway] Error while processing event: #{e.message}"
      end

      sleep 1 until @stopping
    end

    def identify
      payload = {
        op: 2,
        d: {
          token: @token,
          intents: @intents,
          properties: {
            "$os": "linux",
            "$browser": "Rubord",
            "$device": "Rubord"
          }
        }
      }

      @ws.send(payload.to_json)
    end

    def reconnect
      @stopping = true
      @heartbeat_thread&.kill rescue nil

      @ws.close rescue nil
      sleep 2

      @stopping = false
      connect
    end

    def start_heartbeat
      return unless @heartbeat_interval

      @heartbeat_thread&.kill rescue nil

      @heartbeat_thread = Thread.new do
        loop do
          sleep @heartbeat_interval
          break if @stopping || !@ws

          @last_heartbeat_at = Time.now
          @ws.send({ op: 1, d: @seq }.to_json)
        rescue
          reconnect
          break
        end
      end
    end
  end
end