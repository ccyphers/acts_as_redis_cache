module ActionController
  class Base
    def self.acts_as_redis_cache(*args)
      self.class_eval do
        @acts_as_redis_cache_map ||= []
        class << self
          attr_accessor :acts_as_redis_cache_map
        end

        acts_as_redis_cache_map << args
        acts_as_redis_cache_map.flatten!

        include ActsAsRedisCache
      end
    end

    module ActsAsRedisCache
      def self.included(klass)
        klass.class_eval do

          klass.before_action :set_redis_cache_keys, :only => acts_as_redis_cache_map
          klass.before_action :get_cache_for_act_as_redis_cacheable, :only => acts_as_redis_cache_map
          klass.after_action :set_cache_for_act_as_redis_cacheable, :only => acts_as_redis_cache_map

          @@redis = Redis.new

          private

          def params_sum
            sum = ""
            params.each { |k, v| sum += "#{k}=#{v}" }
            Digest::MD5.hexdigest(sum)
          end

          def redis
            @@redis
          end

          def set_redis_cache_keys
            @cache_key = "#{params[:controller]}_#{params[:action]}_#{params_sum}"
          end

          def set_cache_for_act_as_redis_cacheable
            unless has_cache_for_act_as_redis_cacheable
              redis.set(@cache_key, response.body)
              if instance_variables.include?(:@keyed_ids)
                @keyed_ids.each { |k, ids|
                  key = "#{@cache_key}_#{k}"
                  redis.sadd(key, ids)
                }
              end
            end

          end

          def get_cache_for_act_as_redis_cacheable
            if has_cache_for_act_as_redis_cacheable
              render :text => redis.get(@cache_key) and return
            end
          end

          def has_cache_for_act_as_redis_cacheable
            redis.keys.include?(@cache_key)
          end

        end
      end
    end


  end
end
