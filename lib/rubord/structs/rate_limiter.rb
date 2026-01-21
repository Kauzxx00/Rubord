module Rubord
  class RateLimiter
    class Bucket
      attr_reader :id, :limit, :remaining, :reset_at, :queue, :last_request_at

      def initialize(id)
        @id = id
        @limit = 1
        @remaining = 1
        @reset_at = Time.now
        @queue = []
        @last_request_at = nil
        @mutex = Mutex.new
      end

      def available?
        @mutex.synchronize do
          now = Time.now
          
          if now >= @reset_at
            @remaining = @limit
            @reset_at = now + 1
          end
          
          @remaining > 0
        end
      end

      def wait
        @mutex.synchronize do
          now = Time.now
          
          if now < @reset_at && @remaining <= 0
            sleep_time = @reset_at - now
            sleep(sleep_time) if sleep_time > 0
            @remaining = @limit
          end
        end
      end

      def update_from_headers(headers)
        @mutex.synchronize do
          limit_header = headers["x-ratelimit-limit"]
          remaining_header = headers["x-ratelimit-remaining"]
          reset_after_header = headers["x-ratelimit-reset-after"]
          reset_header = headers["x-ratelimit-reset"]
          
          limit_value = Array(limit_header).first
          remaining_value = Array(remaining_header).first
          reset_after_value = Array(reset_after_header).first
          reset_value = Array(reset_header).first
          
          @limit = limit_value&.to_i || @limit
          @remaining = remaining_value&.to_i || @remaining
          
          if reset_after_value
            @reset_at = Time.now + reset_after_value.to_f
          elsif reset_value
            @reset_at = Time.at(reset_value.to_i)
          end
          
          @last_request_at = Time.now
        end
      end

      def reset_in
        [0, @reset_at - Time.now].max
      end
    end

    class GlobalLimiter
      def initialize
        @reset_at = Time.now
        @mutex = Mutex.new
      end

      def blocked?
        @mutex.synchronize { Time.now < @reset_at }
      end

      def block_for(seconds)
        @mutex.synchronize do
          @reset_at = Time.now + seconds
        end
      end

      def wait
        @mutex.synchronize do
          if Time.now < @reset_at
            sleep_time = @reset_at - Time.now
            sleep(sleep_time) if sleep_time > 0
          end
        end
      end
    end

    def initialize
      @buckets = {}
      @route_buckets = {}
      @global_limiter = GlobalLimiter.new
      @mutex = Mutex.new
      @default_bucket = Bucket.new("default")
    end

    def bucket_for(route)
      @mutex.synchronize do
        bucket_id = @route_buckets[route]
        
        if bucket_id
          @buckets[bucket_id] ||= Bucket.new(bucket_id)
        else
          @default_bucket
        end
      end
    end

    def update_mapping(route, bucket_id)
      @mutex.synchronize do
        @route_buckets[route] = bucket_id
        @buckets[bucket_id] ||= Bucket.new(bucket_id)
      end
    end

    def wait_global
      @global_limiter.wait
    end

    def wait_for(route)
      bucket = bucket_for(route)
      bucket.wait
    end

    def handle_rate_limit(headers, body)
      if body["global"] == true
        @global_limiter.block_for(body["retry_after"])
        return :global
      else
        bucket_header = headers["x-ratelimit-bucket"]
        bucket_id = Array(bucket_header).first if bucket_header
        
        if bucket_id
          @mutex.synchronize do
            @buckets[bucket_id] ||= Bucket.new(bucket_id)
            @buckets[bucket_id].reset_at = Time.now + body["retry_after"]
            @buckets[bucket_id].remaining = 0
          end
        end
        return :route
      end
    end

    def update_bucket(route, headers)
      bucket_header = headers["x-ratelimit-bucket"]
      bucket_id = Array(bucket_header).first if bucket_header
      return unless bucket_id

      update_mapping(route, bucket_id)
      
      bucket = @buckets[bucket_id]
      bucket.update_from_headers(headers)
    end
  end
end