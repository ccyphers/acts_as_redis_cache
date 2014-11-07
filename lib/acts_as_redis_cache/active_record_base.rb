class ActiveRecord::Base
  def self.acts_as_redis_cache(*args)
    self.class_eval do
      @@acts_as_redis_cache_map ||= {}
      @@redis = Redis.new

      before_save :acts_as_redis_cache_revalidate_cache

      args.each { |arg|
        next unless arg.kind_of? Hash

        arg.each { |k, v|
          v[:dirty_keys] ||= []
          @@acts_as_redis_cache_map[k] = v[:dirty_keys]
        }

        def acts_as_redis_cache_revalidate_cache
          if errors.empty? and changes != {}

            cache_dirty = false

            @@acts_as_redis_cache_map.each { |k, v|
              v.each { |i|
                if @@redis.sismember("#{k}_#{i}", id)
                  cache_dirty = true
                  break
                end
              }

              @@redis.keys.each { |r_key|
                if r_key == k or r_key =~ /^#{k}_/
                  @@redis.del(r_key)
                end
              }
            }
          end
        end
      }
    end
  end
end

