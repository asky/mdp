class PostTag < ApplicationModel
  belongs_to :tag, :class_name => "Tag", :foreign_key => "tag_id"
  belongs_to :post, :class_name => "Post", :foreign_key => "post_id", :counter_cache => :tag_count

  validates_presence_of :tag_id, :post_id
  validates_uniqueness_of  :tag_id, :scope => [:post_id]
  

  def self.generate(arg = {})
    tag_id = arg[:tag_id]
    post_id = arg[:post_id]
    postTag = find(:first, :conditions => ["tag_id = ? AND post_id = ?", tag_id, post_id])
    if postTag.nil?
      postTag = new(:tag_id => tag_id, :post_id => post_id)
      return false unless postTag.save
    else
      return false
    end
    
    return true
  end

end
