class AttachFilesController < ApplicationController
  before_filter :http_get, :only => [:list, :store_list, :post_list]
  before_filter :http_post, :only => [:upload, :profile_upload]
  before_filter :authentication_required, :only => [:upload, :profile_upload]
  respond_to :xml, :json
  

  def upload
    if parameters_required :upload_file, :post_id
      post = Post.find(:first, :conditions => ["id = ?",params[:post_id]])
      if post.nil?
        __error(:code => 0, :description => "Not exist such a post id")
        return
      elsif post.user_id != current_user.id
        __error(:code => 0, :description => "Non authentication about uploading an image to the post")
        return
      end
        
      require "attach_file_cache_manager"
      fcm = AttachFileCacheManager.new(params[:post_id])
      fcm.add_img(params[:upload_file])
      attach_file_data = {
        :user_id => current_user.id,
        :post_id => params[:post_id],
        :filename => fcm.img_filename,
        :fullpath => fcm.img_path
      }
      
      
      attach_file_data[:store_id] = post.store_id
      
      attach_file = AttachFile.new(attach_file_data)
      if attach_file.save
        __success(attach_file)
        return
      else
        __error(:code => 0, :description => "Failed to save")
      end
    end
  end

  
  def profile_upload
    if parameters_required :upload_file
      require "user_file_cache_manager"
      fcm = UserFileCacheManager.new(current_user.id)
      fcm.add_img(params[:upload_file])
      attach_file_data = {
        :user_id => current_user.id,
        :filename => fcm.img_filename,
        :fullpath => fcm.img_path
      }

      attach_file = AttachFile.new(attach_file_data)
      if attach_file.save
        __success(attach_file)
        return
      else
        __error(:code => 0, :description => "Failed to save")
      end
    end
  end
  
  
  def image
    attach_file = AttachFile.find(:first, :conditions => ["id = ?", params[:attach_file_id]])
    
    if attach_file
      path = Rails.root.to_s + "/" + attach_file.fullpath
      
      size = :l
      size = params[:size].to_sym if params[:size]
      
      case size
      when :ss
        path << 'img_thumbnail_ss/'
      when :s
        path << 'img_thumbnail_s/'
      when :m
        path << 'img_thumbnail_m/'
      when :l
        path << 'img_thumbnail_l/'
      when :xl
        path << 'img_thumbnail_xl/'
      when :original
        path << 'img_original/'
      end
      
      path << attach_file.filename
      path = Rails.root.to_s + '/public/images/profile_default_img' unless File.exist? path
    else
      # Default image
      path = Rails.root.to_s + '/public/images/profile_default_img'
    end
    
    send_file path, :type => 'image/jpeg', :disposition => 'inline'
    #render :file => path, :layout => false
  end

  def list
    ret = __find(AttachFile)
    __respond_with ret, :include => [], :except => []
  end


  def store_list
    if parameters_required :store_id
      conditions = {:store_id => params[:store_id]}
      ret = __find(AttachFile,conditions)
      __respond_with ret, :include => [], :except => []
    end
  end

  def post_list
    if parameters_required :post_id
      conditions = {:post_id => params[:post_id]}
      ret = __find(AttachFile,conditions)
      __respond_with ret, :include => [], :except => []      
    end    
  end
  

end
