class MessagesController < ApplicationController
  def create
    @conversation = current_user.conversations.find(params[:conversation_id])
    content = params.dig(:message, :content).to_s.strip
    return head :unprocessable_entity if content.blank?

    @conversation.messages.create!(role: "user", content: content)
    CoachReplyJob.perform_later(@conversation.messages.create!(role: "assistant", status: "pending"))

    respond_to do |format|
      format.turbo_stream { head :ok } # meddelandena kommer via broadcast
      format.html { redirect_to @conversation }
    end
  end
end
