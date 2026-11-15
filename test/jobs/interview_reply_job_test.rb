require "test_helper"

class InterviewReplyJobTest < ActiveJob::TestCase
  setup do
    @conversation = Onboarding::Interview.start!(users(:one))
    @conversation.messages.create!(role: "user", content: "Jag vill sova bättre.")
    @reply = @conversation.messages.create!(role: "assistant", status: "pending")
  end

  test "replies and updates the profile draft" do
    FakeAi.respond_with("Vad stör sömnen mest?", { summary: "Du vill sova bättre.", confidence: 2 })

    InterviewReplyJob.perform_now(@reply)

    assert_equal "Vad stör sömnen mest?", @reply.reload.content
    assert_equal 2, @conversation.reload.profile_draft["confidence"]
  end

  test "an empty reply becomes an error message instead of an endless spinner" do
    FakeAi.respond_with("")

    InterviewReplyJob.perform_now(@reply)

    assert_equal "failed", @reply.reload.status
    assert_equal I18n.t("coach.error", locale: users(:one).locale), @reply.content
  end
end
