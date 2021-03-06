# -*- coding: utf-8 -*-
require "matji_mileage_manager"

class ApplicationController < ActionController::Base
  # protect_from_forgery
  before_filter :get_session_from_token
  after_filter :mileage_action
  
  respond_to :json, :xml
  
  def http_get
    request.get?
  end
  
  def http_post
    request.post?
  end
  

  def get_session_from_token
    if params[:access_token] and !params[:access_token].empty?
      if AccessGrant.access_token_exists?(params[:access_token])
        session[:user] = AccessGrant.user_for_access_token(params[:access_token])
      end
    end
    return true
  end
  

  def authentication_required
    if current_user.nil?
      __error(:code => 0, :description => "The access token is invalid")
      return false
    else
      return true
    end
#     if params[:access_token] and !params[:access_token].empty?
#       # Validate access_token whether exists and not expired
#       if AccessGrant.access_token_exists?(params[:access_token])
# #         if AccessGrant.access_token_expired?(params[:access_token])
# #           return true
# #         else
# #           @msg = "Access token is expired"
# #         end
#         session[:user] = AccessGrant.user_for_access_token(params[:access_token])
#         return true
#       else
#         msg = "The access token is invalid"
#       end
#     else
#       if current_user
#         return true
#       else
#         msg = "Access token parameter is required"
#       end
#     end
    
    # __error(:code => 0, :description => msg)
    # return false
  end



  def login_required
    if session[:user]
      return true
    end
    flash[:warning]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to '/login'
    return false
  end



  def parameters_required(*args)
    invalid = false
    parameter = nil
    args.each do |arg| 
      parameter = arg.to_s
      if params[arg.to_sym].nil?
        invalid = true
        break
      end
    end
    
    if invalid
      msg = "Parameter '#{parameter}' is missing "
      __error(:code => 0, :description => msg)
      return false
    end

    return true
  end


  def current_user
    session[:user]
  end


  def redirect_to_stored
    if return_to = session[:return_to]
      session[:return_to]=nil
      redirect_to(return_to)
    else
      redirect_to :controller=>'users', :action=>'index'
    end
  end


  

  def __find(model, conditions = nil, except = [:created_at, :updated_at, :sequence])
    offset = 0
    limit = 20
    
    if conditions.nil?
      conditions = {}
    end

    cols = Array.new(model.column_names)
    if except
      except = [except] if except.class != Array
      except = except.map { |i| i.to_s }
      cols -= except
    end
    
    if params[:id]
      conditions[:id] = params[:id].split(",") if conditions.class == Hash
      conditions[0] << "AND id = #{params[:id].split(",")}" if conditions.class == Array
    end
    if params[:limit]
      limit = params[:limit].to_i
    end
    if params[:page]
      offset = (params[:page].to_i - 1) * limit
    end
    

    if params[:order]
      ret = model.find(:all, :conditions => conditions, :limit => limit, :offset => offset, :order => params[:order], :select => cols)
    else
      ret = model.find(:all, :conditions => conditions, :limit => limit, :offset => offset, :order => "sequence ASC", :select => cols)      
    end
    
    return ret
  end
  

  def __error(arg = {})
    if arg[:code].nil?
      arg[:code] = 0
    end
    if arg[:template].nil?
      arg[:template] = 'errors/error'
    end

    ret = {:code => arg[:code], :description => arg[:description]}
    @code = arg[:code]
    @msg = arg[:description]
    respond_with(ret) do |format|
      format.xml {render :xml => ret}
      format.json {render :json => ret}
      format.html {render :template => arg[:template]}
    end
  end


  def __success(object = "OK")
    __respond_with object
    # ret = {:code => 200}
    # ret[:result] = object if object
    # respond_with(ret) do |format|
    #   format.xml {render :xml => ret}
    #   format.json {render :json => ret}
    #   format.html {render :template => 'xmls/xml'}
    # end
  end
  
  def __respond_with(resource, options={})
    if options.nil? 
      options = {}
    end
    
    options[:auth] = current_user
    options[:include] = [] if options[:include].nil?
    options[:except] = [] if options[:except].nil?
    options[:include] += params[:include].split(",").map(&:to_sym) if params[:include]
    options[:except] += params[:except].split(",") if params[:except]
    options[:except] += ["hashed_password","salt","old_hashed_password"]
    options[:except] += ["user.hashed_password","user.salt","user.old_hashed_password"]
    
    # if params[:except]
    #    except_attrs = params[:except].split(",").map {|attr| attr.to_sym}
    #    options[:except] += except_attrs
    # end
    
    resource = {:code => 200, :result => resource}
   
    respond_to do |format|
      format.json do 
        options[:json] = resource
        render options
      end
      format.xml do 
        root = ( resource.is_a?(Array) || resource.is_a?(ThinkingSphinx::Search) ) ? resource.first.class.to_s.downcase : resource.class.to_s.downcase
        
        render :template => "xmls/xml", :text => resource.as_json(options).to_xml(:root => root)
      end
      format.html do
        render
      end
    end
  end
  


  def mileage_action
    return true if current_user.nil? 
    
    # if @code == 200
    #   mmm = MatjiMileageManager.new(user_id, controller, action)
    #   mmm.check
    # end
    

    mmm = MatjiMileageManager.new(current_user.id)
    if mmm and @code == 200
      rule = mmm.act(params[:controller], params[:action])
      
      unless rule.nil?

        rule.each do |node|

          user_id = (node[:to] == "me") ? mmm.from_user_id : @mmm_user_id
          
          # Exception Catch
          return mmm.error if user_id.nil?

          MileageStackData.create(
                                  :user_id => user_id,
                                  :flag => node[:flag],
                                  :point => node[:point],
                                  :from_user_id => mmm.from_user_id
                                  )

          um = UserMileage.find_by_user_id(user_id)
          um = UserMileage.new(:user_id => current_user.id) unless um
          um[:total_point] += node[:point].to_i
          um.save

        end

      end
    end
  end
    
end
