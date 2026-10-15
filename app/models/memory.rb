# Något Lumia har lärt sig om användaren. Alltid synligt och redigerbart på
# /memories – användaren ska kunna se exakt vad coachen tror sig veta.
class Memory < ApplicationRecord
  CATEGORIES = %w[fact preference value goal health pattern learning].freeze
  SOURCES = %w[ai user experiment].freeze

  belongs_to :user
  belongs_to :origin, polymorphic: true, optional: true

  validates :content, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :source, inclusion: { in: SOURCES }

  scope :current, -> { where(archived_at: nil) }
  scope :ordered, -> { order(pinned: :desc, updated_at: :desc) }

  def area = area_key.presence && Area.find(area_key)
  def archive! = update!(archived_at: Time.current)
end
