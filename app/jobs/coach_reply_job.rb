# Coachens svar i chatten. Strömmar texten till meddelandet via Turbo Streams.
class CoachReplyJob < ApplicationJob
  include ReplyStreaming
  queue_as :default

  def perform(reply)
    conversation = reply.conversation
    user = conversation.user
    context = Coach::Context.new(user, focus_area: conversation.area_key)
    task = "TASK: Have a coaching conversation. Be concise (usually under 200 words), personal and concrete. " \
           "Refer to what you know about the person when relevant. End with at most one question."
    history = conversation.messages.where.not(id: reply.id).last(20).map { { role: _1.role, content: _1.content } }
    messages = [ { role: "system", content: context.system_prompt(task) } ] + history

    stream_reply(reply, messages, max_tokens: 1500)
    conversation.update!(title: conversation.messages.first.content.truncate(60)) if conversation.title.blank?

    # Det användaren skrev blir en loggpost, så att minnen och mätvärden
    # plockas ut på samma sätt som från dagboken.
    last_user = conversation.messages.where(role: "user").last
    user.entries.create!(body: last_user.content, source: "chat", area_keys: Array(conversation.area_key)) if last_user
  rescue StandardError => e
    Rails.logger.error "[CoachReplyJob] #{e.class}: #{e.message}"
    reply.update!(content: I18n.t("coach.error", locale: user&.locale || I18n.default_locale), status: "failed")
  end
end
