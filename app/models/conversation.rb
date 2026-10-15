class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  scope :recent, -> { order(updated_at: :desc) }

  def display_title = title.presence || I18n.l(created_at, format: :short)
end
