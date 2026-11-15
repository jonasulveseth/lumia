class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation, touch: true

  validates :role, inclusion: { in: ROLES }

  # Nya meddelanden läggs till av svaret på formuläret (ordningen blir då alltid rätt);
  # bara uppdateringar av det strömmande svaret går via broadcast.
  after_update_commit -> { broadcast_replace_to conversation }

  # Klart att visa som det är: chatten väntar inte på fler uppdateringar.
  def final? = user? || status.in?(%w[done failed])

  def user? = role == "user"
  def assistant? = role == "assistant"
end
