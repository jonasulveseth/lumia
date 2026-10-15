# Provsvar, journalkopior och liknande. DocumentAnalysisJob läser texten och
# sparar varje provvärde som Measurement.
class Document < ApplicationRecord
  KINDS = %w[lab_result medical_record other].freeze
  STATUSES = %w[pending processing done failed].freeze

  belongs_to :user
  has_one_attached :file
  has_many :measurements, as: :source, dependent: :destroy

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validate :file_or_text_present

  after_create_commit -> { DocumentAnalysisJob.perform_later(self) }
  after_update_commit -> { broadcast_refresh_later_to [ user, :documents ] }

  scope :recent, -> { order(Arel.sql("COALESCE(taken_on, created_at::date) DESC")) }

  private

  def file_or_text_present
    errors.add(:base, :file_or_text_missing) unless file.attached? || extracted_text.present?
  end
end
