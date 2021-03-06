class MatjiFileCacheManager

  def initialize(id)
    Dir.chdir(Rails.root.to_s << '/public')
  end


  def add_img(img)
    timestamp = Time.new.to_f
    @filename = Digest::MD5.hexdigest(timestamp.to_s + @path)
    filepath = @path + "/img_original/#{@filename}"
    
    while File.exist? filepath do
      @filename = Digest::MD5.hexdigest(@filename)
      filepath = @path + "/img_original/#{@filename}"
    end

    File.open(filepath, "wb") do |f|
      f.write img.read
    end

    require 'RMagick'

    # xl 640
    # l 512
    # m 256
    # s 128
    # ss 64
    thum_img = Magick::ImageList.new("#{@path}/img_original/#{@filename}")
    width = thum_img.columns
    height = thum_img.rows
    ratio = height.to_f / width.to_f
    
    thum_img.resize!(640, 640 * ratio) if width > 640
    thum_img.write("#{@path}/img_thumbnail_xl/#{@filename}")
    thum_img.resize!(512, 512 * ratio) if width > 512
    thum_img.write("#{@path}/img_thumbnail_l/#{@filename}")
    thum_img.resize!(256, 256 * ratio) if width > 256
    thum_img.write("#{@path}/img_thumbnail_m/#{@filename}")
    thum_img.resize!(128, 128 * ratio) if width > 128
    thum_img.write("#{@path}/img_thumbnail_s/#{@filename}")
    thum_img.resize!(64, 64 * ratio) if width > 64
    thum_img.write("#{@path}/img_thumbnail_ss/#{@filename}")
  end


  def img_filename
    return @filename
  end
  

  def img_path()
    return @path + "/"
  end



  def make_file_cache_dir
    ud = @webPath.split("/")
    File.umask(0)
    ud.each do |w| 
      unless w == ""
        Dir.mkdir(w, 0777) unless File.exist? w
        Dir.chdir(w)
      end
    end
    
    Dir.mkdir("img_original") unless File.exist? "img_original"
    Dir.mkdir("img_thumbnail_xl") unless File.exist? "img_thumbnail_xl"
    Dir.mkdir("img_thumbnail_l") unless File.exist? "img_thumbnail_l"
    Dir.mkdir("img_thumbnail_m") unless File.exist? "img_thumbnail_m"
    Dir.mkdir("img_thumbnail_s") unless File.exist? "img_thumbnail_s"
    Dir.mkdir("img_thumbnail_ss") unless File.exist? "img_thumbnail_ss"

    
    Dir.chdir(Rails.root.to_s)
  end


end
