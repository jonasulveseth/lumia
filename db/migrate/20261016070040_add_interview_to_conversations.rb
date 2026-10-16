# Onboarding sker som en intervju i chatten. Samtalet markeras med kind
# "interview" och profilen som växer fram under samtalet sparas i profile_draft.
class AddInterviewToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :kind, :string, null: false, default: "coach"
    add_column :conversations, :profile_draft, :jsonb, null: false, default: {}
    add_index :conversations, [ :user_id, :kind ]
  end
end
