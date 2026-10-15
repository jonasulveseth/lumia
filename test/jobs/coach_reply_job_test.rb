require "test_helper"

class CoachReplyJobTest < ActiveJob::TestCase
  test "saves the whole streamed reply even after an intermediate save" do
    conversation = users(:one).conversations.create!
    conversation.messages.create!(role: "user", content: "Varför är jag trött?")
    reply = conversation.messages.create!(role: "assistant", status: "pending")
    FakeAi.respond_with("Sömnen verkar vara nyckeln. Vad hindrar dig från att lägga dig tidigare?")
    # Bara första biten hinner sparas under strömningen; resten måste komma
    # med i slutsparningen.
    freeze_time
    FakeAi.before_chunk = ->(i) { travel 1.second if i.zero? }

    CoachReplyJob.perform_now(reply)

    assert_equal "Sömnen verkar vara nyckeln. Vad hindrar dig från att lägga dig tidigare?", reply.reload.content
    assert_equal "done", reply.status
  end
end
