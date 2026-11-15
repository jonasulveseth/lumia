class MessagesController < ApplicationController
  def create
    @conversation = current_user.conversations.coaching.find(params[:conversation_id])
    content = params.dig(:message, :content).to_s.strip
    return head :unprocessable_entity if content.blank?

    message = @conversation.messages.create!(role: "user", content: content)
    reply = @conversation.messages.create!(role: "assistant", status: "pending")
    CoachReplyJob.perform_later(reply)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "messages/message", collection: [ message, reply ]) }
      format.html { redirect_to @conversation }
    end
  end
end
