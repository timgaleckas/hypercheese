class Tag < ActiveRecord::Base
  belongs_to :icon, class_name: 'Item', foreign_key: "icon_item_id"
  has_many :item_tags
  has_many :items, through: :item_tags
  has_many :tag_aliases

  def parent
    return nil unless self.parent_tag_id
    Tag.find self.parent_tag_id rescue nil
  end

  def self.find_by_label(label)
    where('lower(label) = ?', label.downcase).first
  end

  def self.hidden
    find_by_label('Hidden')
  end

  def self.deleted
    find_by_label('delete')
  end
end
