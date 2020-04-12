class AlarmsController < ApplicationController
  before_filter :authentication_required, :except => [:list]
  before_filter :http_get, :only =>[:list]
  respond_to :xml, :json
  
  def list
    conditions = {}
    conditions[:received_user_id] = current_user.id
    ret = __find(Alarm, conditions)
    
    __respond_with ret, :include => [:sent_user, :received_user]
  end
  
  
end