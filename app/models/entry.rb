# Inkorgen: allt användaren skriver ner. EntryProcessingJob klassar området,
# plockar ut mätvärden ("sov 6 h") och nya minnen.
class Entry < ApplicationRecord
  KINDS = %w[note journal meal workout sleep win struggle].freeze
  SOURCES = %w[manual chat check_in import].freeze

  belongs_to :user
  has_many :measurements, as: :source, dependent: :destroy

  validates :body, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :source, inclusion: { in: SOURCES }

  before_validation { self.occurred_at ||= Time.current }
  after_create_commit -> { EntryProcessingJob.perform_later(self) }

  scope :recent, -> { order(occurred_at: :desc) }
  scope :in_area, ->(key) { where("? = ANY(area_keys)", key.to_s) }

  def areas = area_keys.filter_map { |k| Area.find(k) }
  def processed? = processed_at.present?
end
