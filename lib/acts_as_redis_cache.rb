base = File.dirname(File.expand_path(__FILE__))
require "#{base}/acts_as_redis_cache/railtie"
require "#{base}/acts_as_redis_cache/action_controller_base"
require "#{base}/acts_as_redis_cache/active_record_base"
require "#{base}/acts_as_redis_cache/devise_sessions_controller"
