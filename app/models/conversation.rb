class Conversation < ApplicationRecord
  # coach: vanlig coachchatt. interview: onboardingintervjun, en per användare.
  KINDS = %w[coach interview].freeze

  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }

  scope :recent, -> { order(updated_at: :desc) }
  scope :coaching, -> { where(kind: "coach") }

  def interview? = kind == "interview"
  def display_title = title.presence || I18n.l(created_at, format: :short)
end
