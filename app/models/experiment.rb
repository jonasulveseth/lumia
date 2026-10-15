# Ett litet experiment: "vad testar jag nu, och vad lärde jag mig?"
class Experiment < ApplicationRecord
  STATUSES = %w[planned running completed abandoned].freeze

  belongs_to :user

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :success_rating, numericality: { in: 1..10 }, allow_nil: true

  before_validation { self.starts_on ||= Date.current if status == "running" }
  after_update_commit :remember_learning, if: -> { saved_change_to_learning? && learning.present? }

  scope :active, -> { where(status: %w[planned running]) }
  scope :finished, -> { where(status: %w[completed abandoned]) }
  scope :running, -> { where(status: "running") }

  def area = area_key.presence && Area.find(area_key)
  def approach = approach_key.presence && Approach.find(approach_key)

  def days_left
    return unless ends_on && status == "running"
    (ends_on - Date.current).to_i
  end

  private

  def remember_learning
    user.memories.create!(content: "#{title}: #{learning}", category: "learning", area_key: area_key,
                          source: "experiment", origin: self)
  end
end
