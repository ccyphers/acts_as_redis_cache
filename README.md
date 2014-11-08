## ACTS_AS_REDIS_CACHE



### Transparent caching for controller actions

If you want the ability to cache the response data from a controller action with ease at the same time being able to keep track of the IDs associated with a cache set, so that the cache can be deleted when the DB is updated some before and after filters have been provided.  At the beginning of your controller class definition you need to call the class method "acts_as_redis_cache":

    acts_as_redis_cache :<controller method 1>,...,:<controller method N>
    
By calling acts_as_redis_cache, some before and after filters are automatically created which handles all aspects of handling the cache.
    
In order to keep track of which IDs are associated with a cache inside controller actions simply set a key in the instance variable @keyed_ids.  @keyed_ids will be created for you as an empty array in a before filter so you don't need to worry about initializing this.  For example:

    class UserController < ActionController::Base
      def show
        render :json => User.some_model_class_method
      end
    end
    

You would update it to:

    class UserController < ActionController::Base
      acts_as_redis_cache :show
      
      def show
        users = User.some_model_class_method
        @keyed_ids[:user_ids] = users.map { |i| i.id }
        render :json => users
      end
    end

    
If your model data is more complex, containing multiple tables that are joined together make sure that you create unique keys in @keyed_ids for each associated table that make up the cacheable item, in this case,  User.some_model_class_method.


### Structure of the controller action cache

Since a controller can dynamically decide what data to render to the client based on the input data in params, the params is hashed as part of the cache key.  So a given action could have multiple cached items based on the number of request that have hit the resource with different input data.  The base cache key is composed of:

    params[:controller] + params[:action]
    
Appended is the sum of the parameters:

    def params_sum
      sum = ""
      # need to ensure order
      params.keys.sort.each { |k| sum += "#{k}=#{params[k]}" }
      Digest::MD5.hexdigest(sum)
    end


So the complete base key becomes:

    cache_key = "#{params[:controller]}_#{params[:action]}_#{params_sum}"
    
    
For each key in @keyed_ids the array of IDs is stored in a redis set:

    @keyed_ids.each { |k, ids|
      key = "#{@cache_key}_#{k}"
      redis.sadd(key, ids)
    }

The cache for the controller action is simply the response.body as this processing is taking place in an after_filter:

    redis.set(@cache_key, response.body)

### Serving up cached response data

In a before_action filter created for you, "get_cache_for_act_as_redis_cacheable", checks to see if there is cache data available and renders that if founds else allows the request to continue to your controller action for processing.  You should never have to worry about stale cache data as long as you setup the @cache_key references properly and then wire up the required call in your model(s) which will be covered below.

## Flushing cache data with before_save filter

Inside of your model, you need to call acts_as_redis_cache, which will automatically setup a before_save filter to delte all cache keys when the model's instance ID is found in the associated @keyed_ids set.

    class User < ActiveRecord::Base
    
      acts_as_redis_cache "users/show" => [:user_ids]
      
      def self.some_model_class_method
        ...
        ...
      end
    end
    
acts_as_redis_cache takes an array of hashes, so you can have many pairs defined, which is needed for cases that multiple controller actions reference the same model for cache data.  Also, if a given controller action results in multiple tables joined together, make sure to puth the acts_as_redis_cache in each model associated with the JOIN.

When the before_filter is called, it first checks the cached set for :user_ids associated with the defined path and if the current model instance's ID is found in the set, it then knows that the cache data is dirty and simply deletes all keys associated with this cache data.  Then on the next request to the controller, the controller's before filter will see there's no cache available and fall back to the user's controller to build the response followed by caching the new data.

## Configuration

In your environments/<env>.rb you can define the redis connection info via:

config.acts_as_redis_cache = {:redis_host => 'ip or hostname', :redis_port => port_number}

If left blank this defaults to:

config.acts_as_redis_cache = {:redis_host => '127.0.0.1', :redis_port => 6379}


