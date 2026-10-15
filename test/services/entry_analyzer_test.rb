require "test_helper"

class EntryAnalyzerTest < ActiveSupport::TestCase
  test "classifies areas, saves measurements and new memories" do
    user = users(:one)
    entry = user.entries.create!(body: "Sov 6,5 timmar. Humör 7. Jag mår bäst när jag tränar på morgonen.")
    FakeAi.respond_with(
      areas: %w[health mind bogus], kind: "sleep",
      measurements: [ { metric: "sleep_hours", value: "6,5" }, { metric: "mood", value: 7 }, { metric: "unknown", value: 1 }, { metric: "mood", value: 99 } ],
      memories: [ { content: "Mår bäst av morgonträning", category: "preference", area: "health" } ]
    )

    EntryAnalyzer.new(entry).call

    entry.reload
    assert_equal %w[health mind], entry.area_keys
    assert_equal "sleep", entry.kind
    assert entry.processed?
    assert_equal({ "sleep_hours" => 6.5, "mood" => 7.0 }, entry.measurements.to_h { [ _1.metric_key, _1.value.to_f ] })
    assert_equal "h", entry.measurements.find_by(metric_key: "sleep_hours").unit
    memory = user.memories.last
    assert_equal "Mår bäst av morgonträning", memory.content
    assert_equal entry, memory.origin
  end

  test "does not duplicate a memory it already has" do
    user = users(:one)
    user.memories.create!(content: "Har två barn")
    entry = user.entries.create!(body: "Barnen var sjuka")
    FakeAi.respond_with(areas: [ "relationships" ], memories: [ { content: "har två barn", category: "fact" } ])

    assert_no_difference("Memory.count") { EntryAnalyzer.new(entry).call }
  end

  test "running the analysis twice does not duplicate measurements" do
    entry = users(:one).entries.create!(body: "Sov 7 timmar")
    2.times do
      FakeAi.respond_with(areas: [ "health" ], measurements: [ { metric: "sleep_hours", value: 7 } ])
      EntryAnalyzer.new(entry).call
    end
    assert_equal 1, entry.measurements.count
  end
end
