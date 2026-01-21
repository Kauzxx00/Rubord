require "websocket-client-simple"
require "json"
require "timeout"

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
      @event_handlers = {}

      @mutex = Mutex.new
    end

    def connect(&block)
      @mutex.synchronize do
        return if @connected && !@stopping

        if @token.nil? || @token.strip.empty?
          raise InvalidTokenError, "Discord token cannot be empty"
        end

        @stopping = false
        @connected = false

        begin
          @ws = WebSocket::Client::Simple.connect(GATEWAY_URL, headers: {
            "User-Agent" => "DiscordBot (https://github.com/kauzxx00/rubord, 1.0.0)",
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
      end

      sleep 1 while !@stopping
    end

    def handle_open
      @latency = 0
    end

    def handle_message(event, &block)
      data = event.data.to_s

      if data.nil? || data.strip.empty?
        Rubord::Logger.warn "[Rubord:Gateway] Received empty payload"
        return
      end

      begin
        payload = JSON.parse(data)
      rescue JSON::ParserError => e
        Rubord::Logger.warn "[Rubord:Gateway] Failed to parse JSON: #{e.message}"
        Rubord::Logger.warn "[Rubord:Gateway] Raw data: #{data.inspect[0..100]}" if data && data.length > 0
        return
      end

      op = payload["op"]
      t = payload["t"]
      d = payload["d"]
      s = payload["s"]

      @mutex.synchronize do
        @seq = s if s && s > 0

        case op
        when OPCODE_HELLO
          handle_hello(d)
        when OPCODE_HEARTBEAT_ACK
          handle_heartbeat_ack
        when OPCODE_RECONNECT
          Rubord::Logger.warn "[Rubord:Gateway] Discord requested reconnect"
          schedule_reconnect
        when OPCODE_INVALID_SESSION
          handle_invalid_session(d)
        when OPCODE_DISPATCH
          handle_dispatch(t, d, &block)
        else
          Rubord::Logger.warn "[Rubord:Gateway] Unhandled opcode: #{op}"
        end
      end
    rescue => e
      Rubord::Logger.warn "[Rubord:Gateway] Error processing message: #{e.message}"
      Rubord::Logger.warn e.backtrace.join("\n") if e.backtrace
    end

    def handle_close(event)
      Rubord::Logger.warn "[Rubord:Gateway] WebSocket connection closed: code=#{event.code}, reason=#{event.reason}"
      cleanup_connection
      schedule_reconnect unless @stopping
    end

    def handle_error(e)
      Rubord::Logger.warn "[Rubord:Gateway] WebSocket error: #{e.message}"
      Rubord::Logger.warn e.backtrace.join("\n") if e.backtrace
      cleanup_connection
      schedule_reconnect unless @stopping
    end

    def handle_hello(data)
      @heartbeat_interval = data["heartbeat_interval"].to_f / 1000.0
      @connected = true

      if @session_id && @seq
        resume_connection
      else
        start_heartbeat
        identify
      end
    end

    def handle_heartbeat_ack
      if @last_heartbeat_at
        @latency = ((Time.now - @last_heartbeat_at) * 1000).round
      end
    end

    def handle_invalid_session(resumable)
      Rubord::Logger.warn "[Rubord:Gateway] Invalid session (resumable: #{resumable})"

      if resumable && @session_id && @seq
        Rubord::Logger.warn "[Rubord:Gateway] Attempting to resume session"
        sleep rand(1..3)
        identify
      else
        Rubord::Logger.warn "[Rubord:Gateway] Starting new session"
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
        "PRESENCE_UPDATE" => :presence_update,
      }

      event_symbol = event_map[event_type]

      if event_symbol && block_given?
        begin
          block.call(event_symbol, data)
        rescue => e
          Rubord::Logger.warn "[Rubord:Gateway] Error in event handler for #{event_type}: #{e.message}"
          Rubord::Logger.warn e.full_message
        end
      elsif event_type && !["PRESENCE_UPDATE", "TYPING_START", "GUILD_MEMBER_UPDATE"].include?(event_type)
        Rubord::Logger.warn "[Rubord:Gateway] Unhandled event: #{event_type}"
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
            "$device": "Rubord",
          },
          compress: false,
          large_threshold: 250,
          shard: [0, 1],
        },
      }

      send_payload(payload)
    end

    def resume_connection
      Rubord::Logger.warn "[Rubord:Gateway] Attempting to resume session #{@session_id} at seq #{@seq}"

      payload = {
        op: 6,
        d: {
          token: @token,
          session_id: @session_id,
          seq: @seq,
        },
      }

      send_payload(payload)
    end

    def start_heartbeat
      return unless @heartbeat_interval && @heartbeat_interval > 0

      @heartbeat_thread&.kill rescue nil

      @heartbeat_thread = Thread.new do
        while !@stopping && @connected
          begin
            sleep @heartbeat_interval

            break if @stopping || !@connected

            if @last_heartbeat_at && (Time.now - @last_heartbeat_at) > (@heartbeat_interval * 3)
              Rubord::Logger.warn "[Rubord:Gateway] No heartbeat ACK received, reconnecting..."
              schedule_reconnect
              break
            end

            heartbeat_payload = { op: OPCODE_HEARTBEAT, d: @seq }
            @last_heartbeat_at = Time.now
            send_payload(heartbeat_payload)

            Rubord::Logger.warn "[Rubord:Gateway] Sent heartbeat (seq: #{@seq})" if ENV["DEBUG"]
          rescue => e
            Rubord::Logger.warn "[Rubord:Gateway] Heartbeat error: #{e.message}"
            schedule_reconnect
            break
          end
        end
      end
    end

    def send_payload(payload)
      return if @stopping || !@ws

      begin
        json = payload.to_json
        @ws.send(json)

        if ENV["DEBUG"]
          opcode_name = case payload[:op] || payload["op"]
            when 1 then "HEARTBEAT"
            when 2 then "IDENTIFY"
            when 6 then "RESUME"
            else "OP#{payload[:op] || payload["op"]}"
            end
          Rubord::Logger.warn "[Rubord:Gateway] Sent #{opcode_name}"
        end
      rescue => e
        Rubord::Logger.warn "[Rubord:Gateway] Failed to send payload: #{e.message}"
        schedule_reconnect
      end
    end

    def schedule_reconnect
      return if @stopping

      Thread.new do
        @mutex.synchronize do
          cleanup_connection

          delay = 1
          max_delay = 30

          while !@stopping
            Rubord::Logger.warn "[Rubord:Gateway] Reconnecting in #{delay}s..."
            sleep delay

            begin
              connect
              break if @connected
            rescue => e
              Rubord::Logger.warn "[Rubord:Gateway] Reconnect failed: #{e.message}"
            end

            delay = [delay * 2, max_delay].min
          end
        end
      end
    end

    def cleanup_connection
      @connected = false

      @heartbeat_thread&.kill rescue nil
      @heartbeat_thread = nil

      begin
        @ws&.close if @ws.respond_to?(:close)
      rescue
      end
      @ws = nil
    end

    def reconnect
      Rubord::Logger.warn "[Rubord:Gateway] Manual reconnect requested"
      schedule_reconnect
    end

    def disconnect
      Rubord::Logger.warn "[Rubord:Gateway] Disconnecting..."

      @mutex.synchronize do
        @stopping = true
        @connected = false

        cleanup_connection
      end
    end

    def connected?
      @connected && !@stopping
    end
  end
end
