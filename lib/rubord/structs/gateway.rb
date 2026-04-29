require "websocket-client-simple"
require "json"
require "timeout"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module Rubord
  class Gateway
    GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"

    OPCODE_DISPATCH = 0
    OPCODE_HEARTBEAT = 1
    OPCODE_IDENTIFY = 2
    OPCODE_HELLO = 10
    OPCODE_HEARTBEAT_ACK = 11
    OPCODE_RECONNECT = 7
    OPCODE_INVALID_SESSION = 9

    attr_reader :latency, :session_id, :seq

    def initialize(token, intents)
      @token = token
      @intents = intents
      @seq = nil
      @session_id = nil
      @ws = nil
      @stopping = false
      @connected = false
      @heartbeat_interval = nil
      @last_heartbeat_at = nil
      @latency = 0
      @heartbeat_thread = nil
      @mutex = Mutex.new
      @reconnecting = false
    end

    def connect(&block)
      return if @connected && !@stopping

      if @token.nil? || @token.strip.empty?
        raise InvalidTokenError, "Discord token cannot be empty"
      end

      @stopping = false
      @connected = false

      begin
        @ws = WebSocket::Client::Simple.connect(GATEWAY_URL, headers: {
          "User-Agent" => "DiscordBot (https://github.com/kauzxx00/rubord, 1.0.0)"
        })
      rescue => e
        Rubord::Logger.error "[Rubord:Gateway] Failed to connect to Discord Gateway: #{e.message}"
        schedule_reconnect
        return
      end

      gateway_instance = self

      @ws.on(:open) do
        gateway_instance.handle_open
      end

      @ws.on(:message) do |event|
        gateway_instance.handle_message(event, &block)
      end

      @ws.on(:close) do |event|
        gateway_instance.handle_close(event)
      end

      @ws.on(:error) do |e|
        gateway_instance.handle_error(e)
      end

      loop do
        break if @stopping
        sleep 1
      end
    end

    def handle_open
      @latency = 0
    end

    def handle_message(event, &block)
      data = event.data.to_s.force_encoding("UTF-8")

      return if data.nil? || data.strip.empty?

      begin
        payload = JSON.parse(data)
      rescue
        return
      end

      op = payload["op"]
      t = payload["t"]
      d = payload["d"]
      s = payload["s"]

      @seq = s if s

      case op
      when OPCODE_HELLO
        handle_hello(d)
      when OPCODE_HEARTBEAT_ACK
        handle_heartbeat_ack
      when OPCODE_RECONNECT
        schedule_reconnect
      when OPCODE_INVALID_SESSION
        handle_invalid_session(d)
      when OPCODE_DISPATCH
        handle_dispatch(t, d, &block)
      end
    rescue => e
      Rubord::Logger.warn "[Rubord:Gateway] Error processing message: #{e.message}"
    end

    def handle_close(event)
      cleanup_connection
      schedule_reconnect unless @stopping
    end

    def handle_error(e)
      cleanup_connection
      schedule_reconnect unless @stopping
    end

    def handle_hello(data)
      @heartbeat_interval = data["heartbeat_interval"].to_f / 1000.0
      @connected = true

      start_heartbeat

      if @session_id && @seq
        resume_connection
      else
        identify
      end
    end

    def handle_heartbeat_ack
      if @last_heartbeat_at
        @latency = ((Time.now - @last_heartbeat_at) * 1000).round
      end
    end

    def handle_invalid_session(resumable)
      if resumable && @session_id && @seq
        sleep rand(1..3)
        resume_connection
      else
        @session_id = nil
        @seq = nil
        sleep rand(1..5)
        identify
      end
    end

    def handle_dispatch(event_type, data, &block)
      if event_type == "READY"
        @session_id = data["session_id"]
        @connected = true
      end

      event_map = {
        "READY" => :ready,
        "RESUMED" => :resumed,
        "MESSAGE_CREATE" => :message_create,
        "MESSAGE_UPDATE" => :message_update,
        "MESSAGE_DELETE" => :message_delete,
        "GUILD_CREATE" => :guild_create,
        "GUILD_DELETE" => :guild_delete,
        "CHANNEL_CREATE" => :channel_create,
        "CHANNEL_DELETE" => :channel_delete,
        "INTERACTION_CREATE" => :interaction_create,
        "MESSAGE_REACTION_ADD" => :reaction_add,
        "MESSAGE_REACTION_REMOVE" => :reaction_remove,
        "TYPING_START" => :typing_start,
        "PRESENCE_UPDATE" => :presence_update
      }

      event_symbol = event_map[event_type]

      if event_symbol && block_given?
        begin
          block.call(event_symbol, data)
        rescue
        end
      end
    end

    def identify
      payload = {
        op: OPCODE_IDENTIFY,
        d: {
          token: @token,
          intents: @intents,
          properties: {
            "$os": "linux",
            "$browser": "Rubord",
            "$device": "Rubord"
          },
          compress: false,
          large_threshold: 250,
          shard: [0, 1]
        }
      }

      send_payload(payload)
    end

    def resume_connection
      payload = {
        op: 6,
        d: {
          token: @token,
          session_id: @session_id,
          seq: @seq
        }
      }

      send_payload(payload)
    end

    def start_heartbeat
      return unless @heartbeat_interval && @heartbeat_interval > 0

      @heartbeat_thread&.kill rescue nil

      @heartbeat_thread = Thread.new do
        loop do
          break if @stopping || !@connected

          sleep @heartbeat_interval

          if @last_heartbeat_at && (Time.now - @last_heartbeat_at) > (@heartbeat_interval * 3)
            schedule_reconnect
            break
          end

          @last_heartbeat_at = Time.now
          send_payload({ op: OPCODE_HEARTBEAT, d: @seq })
        rescue
          schedule_reconnect
          break
        end
      end
    end

    def send_payload(payload)
      return if @stopping || !@ws

      begin
        json = payload.to_json.force_encoding("UTF-8")
        @ws.send(json)
      rescue
        schedule_reconnect
      end
    end

    def schedule_reconnect
      return if @stopping || @reconnecting

      @reconnecting = true

      Thread.new do
        delay = 1
        max_delay = 30

        loop do
          break if @stopping

          sleep delay

          begin
            cleanup_connection
            connect
            break if @connected
          rescue
          end

          delay = [delay * 2, max_delay].min
        end

        @reconnecting = false
      end
    end

    def cleanup_connection
      @connected = false

      @heartbeat_thread&.kill rescue nil
      @heartbeat_thread = nil

      begin
        @ws&.close
      rescue
      end

      @ws = nil
    end

    def reconnect
      schedule_reconnect
    end

    def disconnect
      @stopping = true
      cleanup_connection
    end

    def connected?
      @connected && !@stopping
    end
  end
end