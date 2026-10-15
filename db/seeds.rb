# Demoperson för utveckling: bin/rails db:seed
# Logga in med demo@lumia.local / lumiademo1
return unless Rails.env.development?

user = User.find_or_initialize_by(email_address: "demo@lumia.local")
user.update!(name: "Demo Person", password: "lumiademo1", coach_style: "gentle", onboarded_at: Time.current,
             about_me: "Småbarnsförälder, jobbar som utvecklare, vill orka mer och sova bättre.")
user.ensure_life_areas!
{ "health" => 5, "nutrition" => 6, "mind" => 5, "relationships" => 7, "career" => 7, "learning" => 6, "finance" => 6, "meaning" => 6 }
  .each { |key, rating| user.life_area(key).update!(rating: rating) }
user.life_area(:health).update!(focus_goal: "Sova 7 timmar minst fyra nätter i veckan")
%w[mediterranean sleep_first stoicism atomic_habits].each do |key|
  user.approach_choices.find_or_create_by!(approach_key: key) { _1.stance = "resonates" }
end
user.approach_choices.find_or_create_by!(approach_key: "low_carb") { _1.stance = "rejected" }

# Två veckor syntetiska mätvärden så att mönsterletningen har något att hitta.
if user.measurements.where(source: nil).none?
  srand(4)
  14.times do |i|
    day = (i + 1).days.ago.change(hour: 21)
    sleep = [ 5, 5.5, 6, 6.5, 7, 7.5, 8 ].sample
    work = [ 7, 8, 9, 10, 11 ].sample
    user.measurements.create!(metric_key: "sleep_hours", value: sleep, measured_at: day)
    user.measurements.create!(metric_key: "mood", value: (sleep - 2 + rand(-0.8..0.8)).round.clamp(1, 10), measured_at: day)
    user.measurements.create!(metric_key: "work_hours", value: work, measured_at: day)
    user.measurements.create!(metric_key: "stress", value: (work - 4 + rand(-1.0..1.0)).round.clamp(1, 10), measured_at: day)
  end
end
puts "Demo: demo@lumia.local"
