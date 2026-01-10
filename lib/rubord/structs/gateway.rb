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
      raise "token vazio" if @token.nil? || @token.strip.empty?
      gateway = self

      begin
        @ws = WebSocket::Client::Simple.connect(GATEWAY_URL)
      rescue => e
        puts "[Gateway] ERRO ao conectar: #{e.message}"
        raise
      end

      @ws.on(:open) do
        puts "[Gateway] Conexão aberta."
      end

      @ws.on(:message) do |event|
        begin
          payload = JSON.parse(event.data) rescue nil
          next unless payload

          op = payload["op"]
          t  = payload["t"]
          d  = payload["d"]
          @seq = payload["s"] if payload["s"]

          case op
          when 10
            @heartbeat_interval = d["heartbeat_interval"].to_f / 1000.0

            gateway.start_heartbeat
            gateway.identify

          when 11
            if @last_heartbeat_at
              @latency = ((Time.now - @last_heartbeat_at) * 1000).round
            end
          end

          if block
            case t
            when "READY"
              puts "[Gateway] READY recebido."
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
              # Ignorar outros eventos por enquanto
            end
          end

        rescue => e
          puts "[Gateway] ERROR: #{e.message}: #{e.full_message}"
        end
      end

      @ws.on(:close) do |_|
        puts "[Gateway] Conexão fechada."
        @stopping = true
      end

      @ws.on(:error) do |e|
        puts "[Gateway] ERRO WebSocket: #{e.message}"
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

    def start_heartbeat
      return if @heartbeat_interval.nil? || @heartbeat_interval <= 0

      @heartbeat_thread&.kill rescue nil
      @heartbeat_thread = Thread.new do
        loop do
          sleep @heartbeat_interval
          break if @stopping

          @last_heartbeat_at = Time.now

          begin
            @ws.send({ op: 1, d: @seq }.to_json)
          rescue => e
            puts "[Gateway] ERRO no heartbeat: #{e.message}"
          end
        end
      end
    end
  end
end