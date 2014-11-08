class ActsAsRedisCacheRailtie < Rails::Railtie
  initializer "acts_as_redis_cache_railtie.configure_rails_initialization" do |app|

    app.config.instance_eval do
      @acts_as_redis_cache ||= {}
      @acts_as_redis_cache[:host] ||= '127.0.0.1'
      @acts_as_redis_cache[:port] ||= 6379
      class << self
        attr_accessor :acts_as_redis_cache
      end
    end
  end
end
