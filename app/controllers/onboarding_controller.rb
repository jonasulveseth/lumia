# Onboarding är en intervju, inte formulär. Först namn och språk, sedan ett
# samtal där Lumia lär känna personen (Onboarding::Interview). Profilen växer
# fram bredvid chatten och sparas när personen trycker Klar.
class OnboardingController < ApplicationController
  before_action :set_interview, except: :start

  def show
  end

  def start
    current_user.update!(params.expect(user: %i[name locale]))
    interview = Onboarding::Interview.start!(current_user)
    reply_to(interview) if interview.messages.empty?
    redirect_to onboarding_path
  end

  def message
    content = params.dig(:message, :content).to_s.strip
    return head :unprocessable_entity if content.blank? || @conversation.nil?

    message = @conversation.messages.create!(role: "user", content: content)
    reply = reply_to(@conversation)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "messages/message", collection: [ message, reply ]) }
      format.html { redirect_to onboarding_path }
    end
  end

  def finish
    Onboarding::Interview.new(@conversation).apply! if @conversation
    current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?
    redirect_to root_path, notice: t("onboarding.done")
  end

  private

  def set_interview
    @conversation = current_user.interview
    @interview = Onboarding::Interview.new(@conversation) if @conversation
  end

  def reply_to(conversation)
    conversation.messages.create!(role: "assistant", status: "pending").tap { InterviewReplyJob.perform_later(_1) }
  end
end
