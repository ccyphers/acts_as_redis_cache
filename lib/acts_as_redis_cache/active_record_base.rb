class ActiveRecord::Base
  def self.acts_as_redis_cache(*args)
    self.class_eval do
      @@acts_as_redis_cache_map ||= {}
      @@redis = Redis.new(:host => Rails.application.config.acts_as_redis_cache[:redis_host],
                          :port => Rails.application.config.acts_as_redis_cache[:redis_port])
      before_save :acts_as_redis_cache_revalidate_cache
      before_create :acts_as_redis_cache_new_record

      args.each { |arg|
        next unless arg.kind_of? Hash

        arg.each { |k, v|
          raise ArgumentError unless v.kind_of?(Array)
          @@acts_as_redis_cache_map[k] = v
        }

        def acts_as_redis_cache_clear_wrap(is_member_check=true)
          # keep track which keys in redis match the cache for this related
          # dirty data
          #
          cache_dirty = false
          keys_to_delete = []

          @@acts_as_redis_cache_map.each { |path, dirty_keys|
            keys = @@redis.keys.grep(/^#{path}_/)

            dirty_keys.each { |dirty_set|
              dirty_key = keys.grep(/^#{path}_.+_#{dirty_set}$/).first
              if dirty_key
                is_member = is_member_check ? @@redis.sismember(dirty_key, id) : true
                if is_member
                  cache_dirty = true
                  keys_to_delete << keys
                  break
                end
              end
            }
            keys_to_delete.flatten.each { |k| @@redis.del(k) }
          }
        end

        def acts_as_redis_cache_new_record
          acts_as_redis_cache_clear_wrap(false)
        end

        def acts_as_redis_cache_revalidate_cache
          if errors.empty? and changes != {}
            acts_as_redis_cache_clear_wrap
          end
        end
      }
    end
  end
end

