# När veckans reflektion är ifylld svarar coachen med en kort återkoppling och
# 1–3 små steg för kommande vecka.
class CheckInReplyJob < ApplicationJob
  queue_as :default

  def perform(check_in)
    user = check_in.user
    task = <<~TASK
      TASK: The person just completed their weekly check-in (week of #{check_in.week_start}, included below as the
      most recent check-in). Write a short reply (max 180 words, markdown allowed): reflect back what you notice,
      connect it to patterns across areas if any, and propose 1–3 small, concrete steps for next week that fit
      their chosen frameworks and focus goals. If an experiment is running, comment on it.
    TASK
    reply = Ai.chat([ { role: "system", content: Coach::Context.new(user).system_prompt(task) },
                      { role: "user", content: "Here is my check-in for this week." } ], max_tokens: 1200)
    check_in.update!(coach_reply: reply)
    check_in.broadcast_replace_to [ user, :check_ins ], target: "coach_reply", partial: "check_ins/coach_reply", locals: { check_in: check_in }
  end
end
