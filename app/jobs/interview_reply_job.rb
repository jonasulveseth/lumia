# Intervjuarens replik i onboardingen. Strömmar svaret som i coachchatten och
# uppdaterar sedan profilutkastet bredvid chatten.
class InterviewReplyJob < ApplicationJob
  include ReplyStreaming
  queue_as :default

  def perform(reply)
    interview = Onboarding::Interview.new(reply.conversation)
    user = reply.conversation.user
    begin
      stream_reply(reply, interview.reply_messages(except: reply), max_tokens: 800)
    rescue StandardError => e
      Rails.logger.error "[InterviewReplyJob] #{e.class}: #{e.message}"
      return reply.update!(content: I18n.t("coach.error", locale: user.locale), status: "failed")
    end

    # Utkastet uppdateras efter repliken: personen läser medan det räknas.
    return unless interview.answered?
    interview.update_draft!
    interview.broadcast_profile
  rescue StandardError => e
    Rails.logger.error "[InterviewReplyJob] utkastet: #{e.class}: #{e.message}"
  end
end
