# Letar mönster tvärs över livsområden. Två steg:
#   1. Statistik: korrelationer mellan dagliga mätvärden (sömn ↔ humör) och
#      mellan veckoskattningar per område och veckosnitt av mätvärden.
#   2. AI: tolkar siffrorna tillsammans med reflektioner och loggar och skriver
#      några få, konkreta insikter.
# Statistiken skickas med som bevis och sparas på insikten, så att
# användaren kan se vad en insikt bygger på.
class PatternFinder
  MIN_PAIRS = 6
  MIN_R = 0.4
  WINDOW = 120.days

  def initialize(user)
    @user = user
  end

  def call
    correlations = daily_correlations + weekly_correlations
    return [] if correlations.empty? && @user.entries.count < 5 && @user.check_ins.count < 2

    result = Ai.json(system: system_prompt, prompt: prompt(correlations), max_tokens: 3000)
    Array(result["insights"]).first(4).filter_map do |i|
      next if i["title"].blank? || i["body"].blank?
      @user.insights.create!(
        title: i["title"].to_s.truncate(120), body: i["body"],
        kind: Insight::KINDS.include?(i["kind"]) ? i["kind"] : "pattern",
        area_keys: Array(i["areas"]).map(&:to_s) & Area.keys,
        evidence: { correlations: correlations.first(8) }
      )
    end
  end

  # Publik så att den går att testa utan AI.
  def daily_correlations
    series = daily_series
    pairs(series.keys).filter_map { |a, b| correlation_row(a, b, series[a], series[b], "day") }
  end

  def weekly_correlations
    ratings = Hash.new { |h, k| h[k] = {} }
    @user.check_ins.where(week_start: WINDOW.ago.to_date..).each do |c|
      c.ratings.each { |area, v| ratings["rating:#{area}"][c.week_start] = v.to_f if v.present? }
    end
    return [] if ratings.empty?

    weekly = Hash.new { |h, k| h[k] = {} }
    daily_series.each do |metric, days|
      days.group_by { |d, _| d.beginning_of_week }.each { |w, vals| weekly[metric][w] = vals.sum { _2 } / vals.size }
    end

    ratings.keys.product(weekly.keys).filter_map { |a, b| correlation_row(a, b, ratings[a], weekly[b], "week") }
  end

  private

  def daily_series
    @daily_series ||= @user.measurements.where(measured_at: WINDOW.ago..)
      .group(:metric_key, Arel.sql("DATE(measured_at)")).average(:value)
      .each_with_object(Hash.new { |h, k| h[k] = {} }) { |((key, day), avg), h| h[key][day] = avg.to_f }
  end

  def pairs(keys) = keys.sort.combination(2).to_a

  def correlation_row(a, b, sa, sb, unit)
    common = sa.keys & sb.keys
    return if common.size < MIN_PAIRS

    r = pearson(common.map { sa[_1] }, common.map { sb[_1] })
    return if r.nil? || r.abs < MIN_R

    { a: a, b: b, r: r.round(2), n: common.size, per: unit }
  end

  def pearson(xs, ys)
    n = xs.size
    mx, my = xs.sum / n, ys.sum / n
    cov = xs.zip(ys).sum { |x, y| (x - mx) * (y - my) }
    sx = Math.sqrt(xs.sum { (_1 - mx)**2 })
    sy = Math.sqrt(ys.sum { (_1 - my)**2 })
    return nil if sx.zero? || sy.zero?

    cov / (sx * sy)
  end

  def prompt(correlations)
    stats = correlations.map { |c| "- #{c[:a]} vs #{c[:b]}: r=#{c[:r]} (n=#{c[:n]} #{c[:per]}s)" }
    earlier = @user.insights.recent.limit(10).pluck(:title).map { "- #{_1}" }
    <<~TEXT
      Statistical correlations found (Pearson r, |r| >= #{MIN_R}):
      #{stats.join("\n").presence || '(none – rely on the qualitative data)'}

      Insights already given earlier (do not repeat):
      #{earlier.join("\n").presence || '(none)'}
    TEXT
  end

  def system_prompt
    Coach::Context.new(@user).system_prompt(<<~TASK)
      TASK: Find 1–4 meaningful patterns ACROSS life areas (e.g. sleep vs mood, work hours vs relationships,
      alcohol vs energy). Use the statistics when present, otherwise the qualitative check-ins, experiments
      and log entries. Correlation is not causation – phrase carefully and suggest a small experiment to test
      the pattern. Skip anything weak or obvious. Return ONLY JSON:
      {"insights": [{"title": "short headline", "body": "2-4 sentences incl. a suggested experiment",
                     "kind": "pattern" | "correlation" | "suggestion", "areas": [area keys]}]}
    TASK
  end
end
