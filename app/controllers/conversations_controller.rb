class ConversationsController < ApplicationController
  def index
    @conversations = current_user.conversations.recent.limit(30)
    @conversation = current_user.conversations.new(area_key: params[:area])
  end

  def show
    @conversation = current_user.conversations.find(params[:id])
    @conversations = current_user.conversations.recent.limit(30)
  end

  def create
    conversation = current_user.conversations.create!(area_key: params.dig(:conversation, :area_key).presence_in(Area.keys))
    if (content = params.dig(:conversation, :message).to_s.strip).present?
      conversation.messages.create!(role: "user", content: content)
      CoachReplyJob.perform_later(conversation.messages.create!(role: "assistant", status: "pending"))
    end
    redirect_to conversation
  end

  def destroy
    current_user.conversations.find(params[:id]).destroy
    redirect_to coach_path, status: :see_other
  end
end
