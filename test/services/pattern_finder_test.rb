require "test_helper"

class PatternFinderTest < ActiveSupport::TestCase
  test "finds a daily correlation between sleep and mood" do
    user = users(:one)
    [ [ 5, 3 ], [ 6, 5 ], [ 7, 6 ], [ 8, 8 ], [ 6.5, 5 ], [ 7.5, 7 ], [ 5.5, 4 ] ].each_with_index do |(sleep, mood), i|
      at = (i + 1).days.ago
      user.measurements.create!(metric_key: "sleep_hours", value: sleep, measured_at: at)
      user.measurements.create!(metric_key: "mood", value: mood, measured_at: at)
    end

    rows = PatternFinder.new(user).daily_correlations
    assert_equal 1, rows.size
    assert_operator rows.first[:r], :>, 0.9
    assert_equal 7, rows.first[:n]
  end

  test "creates insights from the model's answer" do
    user = users(:one)
    6.times { |i| user.entries.create!(body: "Dag #{i}") }
    FakeAi.respond_with(insights: [ { title: "Sömn och humör", body: "Testa att sova mer.", kind: "correlation", areas: %w[health mind nope] } ])

    insights = PatternFinder.new(user).call
    assert_equal 1, insights.size
    assert_equal %w[health mind], insights.first.area_keys
  end
end
