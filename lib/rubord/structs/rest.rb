require "net/http"
require "uri"
require "openssl"
require "json"
require_relative "rate_limiter"

module Rubord
  class REST
    BASE_URL = "https://discord.com/api/v10"
    
    # Default retry configuration
    MAX_RETRIES = 3
    INITIAL_RETRY_DELAY = 0.5

    def initialize(token)
      @token = token
      @rate_limiter = RateLimiter.new
      @http_pool = {} # Simple HTTP connection pool
    end

    # ========== MÉTODOS PÚBLICOS DA API ==========
    
    def send_message(channel_id, **opts)
      body = build_message_body(**opts)
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

    def edit_message(channel_id, message_id, **opts)
      body = build_message_body(**opts)
      request(:patch, "/channels/#{channel_id}/messages/#{message_id}", body: body)
    end

    def delete_message(channel_id, message_id)
      request(:delete, "/channels/#{channel_id}/messages/#{message_id}")
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

    def get_application_emojis(application_id)
      request(:get, "/applications/#{application_id}/emojis")
    end

    def interactions_response(interaction_id, interaction_token, type: nil, **opts)
      data = build_message_body(**opts)
      body = {
        type: type,
        data: data
      }
      
      request(:post, "/interactions/#{interaction_id}/#{interaction_token}/callback", body: body)
    end

    def interaction_edit(application_id, token, **opts)
      data = build_message_body(**opts)
      body = {
        data: data
      }
      request(:patch, "/webhooks/#{application_id}/#{token}/messages/@original", body: body)
    end

    def interaction_followup(application_id, token, **opts)
      body = build_message_body(**opts)
      request(:post, "/webhooks/#{application_id}/#{token}", body: body)
    end

    def build_message_body(content: nil, embeds: nil, components: nil, flags: nil)
      body = {}

      resolved_flags =
        case flags
        when Array
          Rubord::MessageFlags.combine(*flags)
        when Symbol
          Rubord::MessageFlags.combine(flags)
        when Integer
          flags
        else
          nil
        end

      is_components_v2 =
        resolved_flags &&
        (resolved_flags & Rubord::MessageFlags::COMPONENTS_V2 != 0)

      if is_components_v2
        if content || embeds
          raise ArgumentError, "content/embeds cannot be used with Components V2. Use Rubord::Text or other components."
        end
      else
        body[:content] = content if content
        body[:embeds]  = Array(embeds).map(&:to_h) if embeds
      end

      body[:components] = Array(components).map(&:to_h) if components
      body[:flags]      = resolved_flags if resolved_flags

      body
    end

    def handle_response(res)
      parse_response(res)
    end

    def request(method, path, body: nil, retries: MAX_RETRIES)
      route = extract_route(method, path)
      uri = URI("#{BASE_URL}#{path}")
      
      # Wait for rate limits
      @rate_limiter.wait_global
      @rate_limiter.wait_for(route)
      
      req = build_request(method, uri)
      req.body = JSON.generate(body) if body

      begin
        res = send_http_request(uri, req)
        
        # Handle rate limit responses
        if res.code.to_i == 429
          return handle_rate_limit_response(res, route, method, path, body, retries)
        end
        
        # Handle other errors
        unless res.is_a?(Net::HTTPSuccess)
          raise_api_error(res)
        end
        
        # Update rate limit info
        update_rate_limit_info(route, res)
        
        # Parse and return response
        return parse_response(res)
        
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        return handle_timeout(e, method, path, body, retries)
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        return handle_connection_error(e, method, path, body, retries)
      rescue => e
        # Handle any other unexpected errors
        puts "[REST Error] Unexpected error: #{e.class}: #{e.message}"
        raise e
      end
    end

    private

    # Extract route identifier for rate limiting
    def extract_route(method, path)
      # Remove IDs from path for better bucket matching
      clean_path = path.gsub(/\d+/, ":id")
      "#{method.upcase}:#{clean_path}"
    end

    # Send HTTP request with connection pooling
def send_http_request(uri, req)
  http = @http_pool[uri.host] ||= Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = uri.scheme == "https"
  
  if http.use_ssl? && ENV["TERMUX_VERSION"]
    # Caminhos comuns de certificados no Termux
    possible_certs = [
      "/data/data/com.termux/files/usr/etc/tls/cert.pem",
      "/system/etc/security/cacerts" # Fallback para o Android system
    ]
    
    cert_found = false
    possible_certs.each do |path|
      if File.exist?(path)
        if File.directory?(path)
          http.ca_path = path
        else
          http.ca_file = path
        end
        cert_found = true
        break
      end
    end

    # Se mesmo com ca-certificates instalado der erro, forçamos o modo
    # Isso resolve o erro "exception in verify_callback is ignored"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless cert_found
  end

  http.read_timeout = 30
  http.open_timeout = 10
  
  http.start unless http.started?
  http.request(req)
end

    # Handle rate limit response (429)
    def handle_rate_limit_response(res, route, method, path, body, retries)
      retry_after = extract_retry_after(res)
      is_global = parse_rate_limit_body(res).fetch("global", false)
      
      puts "[Rate Limit] #{is_global ? 'Global' : 'Route'} rate limit hit on #{route}. Waiting #{retry_after}s"
      
      if is_global
        @rate_limiter.handle_rate_limit(res.to_hash, parse_rate_limit_body(res))
      end
      
      sleep(retry_after)
      
      # Retry the request
      if retries > 0
        return request(method, path, body: body, retries: retries - 1)
      else
        raise "Rate limit retries exhausted for #{route}"
      end
    end

    # Update rate limit information from successful response
    def update_rate_limit_info(route, res)
      headers = res.to_hash.transform_keys(&:downcase)
      @rate_limiter.update_bucket(route, headers)
    end

    # Parse response body
    def parse_response(res)
      return nil if res.body.nil? || res.body.empty?
      
      JSON.parse(res.body)
    rescue JSON::ParserError
      res.body
    end

    # Extract retry-after time from response
    def extract_retry_after(res)
      body = parse_rate_limit_body(res)
      
      # Try from body first, then header
      retry_after = body["retry_after"] if body.is_a?(Hash)
      retry_after ||= res["retry-after"] || res["Retry-After"]
      retry_after ||= 1.0
      
      retry_after.to_f
    end

    # Parse rate limit response body
    def parse_rate_limit_body(res)
      return {} if res.body.nil? || res.body.empty?
      
      begin
        JSON.parse(res.body)
      rescue JSON::ParserError
        {}
      end
    end

    # Handle timeout errors with retry
    def handle_timeout(error, method, path, body, retries)
      puts "[Timeout] #{error.message} for #{method} #{path}"
      
      if retries > 0
        sleep(INITIAL_RETRY_DELAY * (MAX_RETRIES - retries + 1))
        return request(method, path, body: body, retries: retries - 1)
      else
        raise "Request timeout after #{MAX_RETRIES} retries"
      end
    end

    def handle_connection_error(error, method, path, body, retries)
      puts "[Connection Error] #{error.class}: #{error.message}"
      
      @http_pool.clear
      
      if retries > 0
        sleep(1 * (MAX_RETRIES - retries + 1))
        return request(method, path, body: body, retries: retries - 1)
      else
        raise "Connection failed after #{MAX_RETRIES} retries"
      end
    end

    def raise_api_error(res)
      body = parse_response(res) || {}
      message = body["message"] || res.message || "HTTP #{res.code}"
      
      error_class = case res.code.to_i
                   when 400 then BadRequestError
                   when 401 then UnauthorizedError
                   when 403 then ForbiddenError
                   when 404 then NotFoundError
                   when 429 then RateLimitError
                   when 500..599 then ServerError
                   else APIError
                   end
      
      raise error_class.new(message, res.code.to_i, body)
    end

    # Build HTTP request
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
      req["User-Agent"]    = "DiscordBot (https://github.com/kauzxx00/rubord, 1.0.0)"
      req
    end
  end

  class APIError < StandardError
    attr_reader :status, :response_body
    
    def initialize(message, status = nil, response_body = nil)
      super(message)
      @status = status
      @response_body = response_body
    end
  end
  
  class BadRequestError < APIError; end
  class UnauthorizedError < APIError; end
  class ForbiddenError < APIError; end
  class NotFoundError < APIError; end
  class RateLimitError < APIError; end
  class ServerError < APIError; end
end