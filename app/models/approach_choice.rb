class ApproachChoice < ApplicationRecord
  STANCES = %w[resonates curious rejected].freeze

  belongs_to :user

  validates :approach_key, inclusion: { in: -> (_) { Approach.keys } }, uniqueness: { scope: :user_id }
  validates :stance, inclusion: { in: STANCES }

  def approach = Approach.find!(approach_key)
end
