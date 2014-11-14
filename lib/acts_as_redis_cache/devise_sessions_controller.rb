class Devise::SessionsController < ActionController::Base
  def sign_in(*args)
    super
    delegate_ = session.instance_variable_get("@delegate")
    if delegate_
      r = Redis.new
      id = Digest::MD5.hexdigest("#{delegate_['warden.user.user.key'].first.first}#{delegate_['warden.user.user.key'].last}")
      r.set(id, {:user_id => current_user.id, :signin_at  => current_user.current_sign_in_at.tv_sec}.to_json)
    end
  end
end

