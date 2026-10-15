class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation, touch: true

  validates :role, inclusion: { in: ROLES }

  after_create_commit -> { broadcast_append_to conversation, target: "messages" }
  after_update_commit -> { broadcast_replace_to conversation }

  def user? = role == "user"
  def assistant? = role == "assistant"
end
