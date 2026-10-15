# Ett mönster tvärs över livsområden ("sämre sömn veckor med mycket jobb").
# Skapas av PatternDetectionJob ur korrelationer och reflektioner.
class Insight < ApplicationRecord
  KINDS = %w[pattern correlation suggestion].freeze
  STATUSES = %w[new useful dismissed].freeze

  belongs_to :user

  validates :title, :body, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :visible, -> { where.not(status: "dismissed") }
  scope :recent, -> { order(created_at: :desc) }

  def areas = area_keys.filter_map { |k| Area.find(k) }
end
