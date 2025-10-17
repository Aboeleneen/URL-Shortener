# redis_client.rb
require 'redis'

class RedisClient
  def self.connect
    @redis ||= Redis.new(
      host: ENV['REDIS_HOST'] || 'redis',
      port: ENV['REDIS_PORT'] || 6379
    )
  end

  def self.get_next_id
    connect.incr("url_counter")
  end

  def self.reset_counter
    connect.del("url_counter")
  end

end
