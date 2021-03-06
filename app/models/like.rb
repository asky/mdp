class Like < ApplicationModel
  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :store, :class_name => "Store", :foreign_key => "foreign_key"
  belongs_to :store_food, :class_name => "StoreFood", :foreign_key => "foreign_key"
  belongs_to :post, :class_name => "Post", :foreign_key => "foreign_key"

  validates_presence_of :user_id, :foreign_key, :object
  validates_uniqueness_of  :user_id, :scope => [:foreign_key, :object]
  validates_inclusion_of :object, :in => %w(Store Post StoreFood)

  after_create :increase_like_count
  before_destroy :decrease_like_count
  
  private
  def increase_like_count
    case object
    when "Store"
      obj = Store.find(foreign_key)
      obj.user_id = self.user_id
    when "Post"
      obj = Post.find(foreign_key)
    when "StoreFood"
      obj = StoreFood.find(foreign_key)
    end
    
    obj.update_attribute(:like_count, obj.like_count + 1)
  end


  def decrease_like_count
    case object
    when "Store"
      obj = Store.find(foreign_key)
    when "Post"
      obj = Post.find(foreign_key)
    when "StoreFood"
      obj = StoreFood.find(foreign_key)
    end
    
    if obj.like_count > 0
      obj.update_attribute(:like_count, obj.like_count - 1)
    end
  end
end
