# Veckans reflektion: skattning per område plus fyra korta frågor.
class CheckIn < ApplicationRecord
  belongs_to :user

  validates :week_start, presence: true, uniqueness: { scope: :user_id }
  validates :energy, numericality: { in: 1..10 }, allow_nil: true

  before_validation { self.week_start ||= Date.current.beginning_of_week }
  after_save_commit :sync_area_ratings

  scope :recent, -> { order(week_start: :desc) }

  def week_number = week_start.cweek

  private

  # Senaste veckans skattning blir områdets aktuella läge.
  def sync_area_ratings
    ratings.each do |key, value|
      next if value.blank?
      user.life_area(key)&.update(rating: value.to_i)
    end
  end
end
