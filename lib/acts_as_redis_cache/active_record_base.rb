class ActiveRecord::Base
  def self.acts_as_redis_cache(*args)
    self.class_eval do
      @@acts_as_redis_cache_map ||= {}
      @@redis = Redis.new(:host => Rails.application.config.acts_as_redis_cache[:redis_host],
                          :port => Rails.application.config.acts_as_redis_cache[:redis_port])
      before_save :acts_as_redis_cache_revalidate_cache

      args.each { |arg|
        next unless arg.kind_of? Hash

        arg.each { |k, v|
          raise ArgumentError unless v.kind_of?(Array)
          @@acts_as_redis_cache_map[k] = v
        }

        def acts_as_redis_cache_revalidate_cache
          if errors.empty? and changes != {}

            cache_dirty = false

            # keep track which keys in redis match the cache for this related
            # dirty data
            #

            keys_to_delete = []

            @@acts_as_redis_cache_map.each { |path, dirty_keys|
              keys = @@redis.keys.grep(/^#{path}_/)

              dirty_keys.each { |dirty_set|
                dirty_key = keys.grep(/^#{path}_.+_#{dirty_set}$/).first
                if dirty_key
                  if @@redis.sismember(dirty_key, id)
                    cache_dirty = true
                    keys_to_delete << keys
                    break
                  end
                end
              }
              keys_to_delete.flatten.each { |k| @@redis.del(k) }
            }
          end
        end
      }
    end
  end
end

