require "test_helper"

class LifeFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "a new person registers, is interviewed and lands on the overview" do
    post registration_path, params: { user: { name: "Kim", email_address: "kim@example.com", password: "hemligt123" } }
    assert_redirected_to onboarding_path
    get root_path
    assert_redirected_to onboarding_path

    get onboarding_path
    assert_response :success
    assert_select "form[action='#{start_onboarding_path}']"

    FakeAi.respond_with("Hej Kim! Vad händer i ditt liv just nu?")
    perform_enqueued_jobs { post start_onboarding_path, params: { user: { name: "Kim", locale: "sv" } } }
    assert_redirected_to onboarding_path
    get onboarding_path
    assert_response :success
    assert_select "#messages", text: /Vad händer i ditt liv/
    assert_select "#interview_progress button[disabled]"

    FakeAi.respond_with("Det låter tungt. Vill du att jag är rak med dig?", {
      summary: "Du vill sova bättre och orka mer.", birth_year: 1985, coach_style: "direct",
      areas: { health: { active: true, rating: 4, current_state: "Sover 5 timmar", focus_goal: "Sova 7 timmar" },
               finance: { active: false }, nonsense: { active: true } },
      approaches: { mediterranean: "resonates", low_carb: "rejected", stoicism: "curious", made_up: "resonates" },
      memories: [ { content: "Har två små barn", category: "fact", area_key: "relationships" } ],
      confidence: 7
    })
    perform_enqueued_jobs do
      post message_onboarding_path, params: { message: { content: "Jag sover dåligt, gillar medelhavskost men inte LCHF." } }, as: :turbo_stream
    end
    get onboarding_path
    assert_select "#interview_progress button:not([disabled])", text: /Klar/
    assert_select "#interview_profile", text: /Sova 7 timmar/

    post finish_onboarding_path
    assert_redirected_to root_path

    user = User.find_by!(email_address: "kim@example.com")
    assert user.onboarded?
    assert_equal "direct", user.coach_style
    assert_equal 1985, user.birth_year
    assert_equal "Du vill sova bättre och orka mer.", user.about_me
    assert_equal 4, user.life_area(:health).rating
    assert_equal "Sova 7 timmar", user.life_area(:health).focus_goal
    refute user.life_area(:finance).active
    assert_equal %w[mediterranean], user.chosen_approaches.map(&:key)
    assert_equal [ "Har två små barn" ], user.memories.pluck(:content)
    assert_empty user.entries, "intervjun ska inte bli loggposter"

    # Klar igen ersätter i stället för att dubblera.
    post finish_onboarding_path
    assert_equal 1, user.memories.count

    get root_path
    assert_response :success
    assert_select "svg polygon"
    get coach_path
    assert_select "a[href='#{conversation_path(user.interview)}']", count: 0
  end

  %w[sv en].each do |locale|
  test "every page renders for an onboarded person (#{locale})" do
    user = users(:one)
    user.update!(locale: locale)
    user.ensure_life_areas!
    user.life_areas.update_all(rating: 7)
    sign_in_as user
    entry = user.entries.create!(body: "Sov 7 h", processed_at: Time.current)
    user.measurements.create!(metric_key: "sleep_hours", value: 7, measured_at: 1.day.ago, source: entry)
    user.measurements.create!(metric_key: "sleep_hours", value: 6, measured_at: 2.days.ago)
    doc = user.documents.create!(title: "Prover", extracted_text: "Hb 140", status: "done", summary: "Allt ser bra ut.")
    check_in = user.check_ins.create!(ratings: { "health" => 6 }, went_well: "Promenader", coach_reply: "**Bra** vecka")
    experiment = user.experiments.create!(title: "Ingen skärm efter 22", area_key: "health", ends_on: 5.days.from_now)
    user.memories.create!(content: "Gillar morgonträning", area_key: "health")
    user.insights.create!(title: "Sömn och humör", body: "Hänger ihop", area_keys: %w[health mind], evidence: { correlations: [ { a: "sleep_hours", b: "mood", r: 0.8, n: 10 } ] })
    conversation = user.conversations.create!(area_key: "health")
    conversation.messages.create!(role: "user", content: "Hej")
    conversation.messages.create!(role: "assistant", content: "Hej på dig")
    interview = user.conversations.create!(kind: "interview", profile_draft: Onboarding::Draft.sanitize(
      summary: "Vill sova bättre", coach_style: "direct", confidence: 4,
      areas: { health: { rating: 5, focus_goal: "Sova 7 h" }, finance: { active: false } },
      approaches: { stoicism: "curious" }, memories: [ "Har barn" ]))
    interview.messages.create!(role: "assistant", content: "Vad händer just nu?")

    [ root_path, areas_path, area_path("health"), area_path("finance"), approaches_path, entries_path, entries_path(area: "health"),
      measurements_path, measurement_path("sleep_hours"), documents_path, new_document_path, document_path(doc),
      check_ins_path, check_in_path(check_in), edit_check_in_path(check_in), experiments_path, new_experiment_path,
      edit_experiment_path(experiment), memories_path, insights_path, coach_path, conversation_path(conversation),
      settings_path, style_guide_path, onboarding_path ].each do |path|
      get path
      assert_response :success, "#{path} gav #{response.status}"
    end

    get new_check_in_path
    assert_redirected_to edit_check_in_path(check_in)
  end
  end

  test "logging, check-in, experiment and chat run their jobs" do
    user = users(:one)
    user.ensure_life_areas!
    sign_in_as user

    FakeAi.respond_with({ areas: [ "health" ], kind: "sleep", measurements: [ { metric: "sleep_hours", value: 5 } ], memories: [] })
    perform_enqueued_jobs do
      post entries_path, params: { entry: { body: "Sov bara 5 timmar" } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal 5, user.measurements.find_by(metric_key: "sleep_hours").value

    FakeAi.respond_with("Bra vecka. Testa att lägga dig 22.30.")
    perform_enqueued_jobs do
      post check_ins_path, params: { check_in: { ratings: { health: "4", mind: "" }, energy: "5", learned: "Sömn styr allt" } }
    end
    check_in = user.check_ins.last
    assert_redirected_to check_in_path(check_in)
    assert_equal({ "health" => 4 }, check_in.ratings)
    assert_equal 4, user.life_area(:health).rating
    assert_match "22.30", check_in.reload.coach_reply

    post experiments_path, params: { experiment: { title: "Lägga mig 22.30", area_key: "health", status: "running" } }
    experiment = user.experiments.last
    patch experiment_path(experiment), params: { experiment: { status: "completed", learning: "Jag somnar fortare" } }
    assert user.memories.exists?(category: "learning", origin: experiment)

    FakeAi.respond_with("Vad tror du själv?", { areas: [ "health" ], memories: [] })
    perform_enqueued_jobs do
      post conversations_path, params: { conversation: { message: "Varför är jag trött?", area_key: "health" } }
    end
    conversation = user.conversations.last
    assert_equal [ "Varför är jag trött?", "Vad tror du själv?" ], conversation.messages.pluck(:content)
    assert_equal "done", conversation.messages.last.status
    assert user.entries.exists?(source: "chat")
    system_prompt = FakeAi.calls.find { _1[:messages].first[:content].include?("TASK: Have a coaching") }[:messages].first[:content]
    assert_includes system_prompt, "Direct and honest".then { user.coach_style == "direct" ? _1 : "Warm" }
  end

  test "data is scoped to the signed-in person" do
    other = users(:two).documents.create!(title: "Andras", extracted_text: "x")
    sign_in_as users(:one)
    get document_path(other)
    assert_response :not_found
  end

  test "approach choice toggles via turbo stream" do
    user = users(:one)
    sign_in_as user
    put choice_approach_path("stoicism"), params: { stance: "resonates" }, as: :turbo_stream
    assert_response :success
    assert_equal "resonates", user.approach_choices.find_by(approach_key: "stoicism").stance
    put choice_approach_path("stoicism"), params: { stance: "resonates" }, as: :turbo_stream
    refute user.approach_choices.exists?(approach_key: "stoicism")
  end
end
