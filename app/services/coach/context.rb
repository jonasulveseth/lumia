module Coach
  # Samlar det Lumia vet om användaren till en text som går in i varje
  # AI-anrop: profil, områden, valda ramverk, minnen, experiment, trender.
  # Det här är det som gör coachningen personlig – samma ramverk för alla,
  # men innehållet kommer härifrån.
  class Context
    def initialize(user, focus_area: nil)
      @user = user
      @focus_area = focus_area
    end

    def to_prompt
      [ profile, areas, approaches, memories, experiments, check_ins, trends, insights, recent_entries ]
        .compact_blank.join("\n\n")
    end

    def language_instruction
      @user.locale == "en" ? "Always answer in English." : "Svara alltid på svenska."
    end

    def system_prompt(task)
      <<~PROMPT
        You are Lumia, a holistic personal life coach. You help one person grow across all areas of life
        (health, nutrition, mind, relationships, career, learning, finance, meaning) and you look for patterns
        between those areas. You respect the frameworks and schools of thought the person has chosen and do
        not push ones they rejected. Suggest small, concrete, testable steps rather than big overhauls.
        You are not a doctor or therapist: for medical values outside reference ranges or signs of serious
        distress, kindly recommend talking to a professional.

        Coaching style: #{Coaching.instruction(@user.coach_style)}
        #{language_instruction}

        #{task}

        === What you know about the person ===
        #{to_prompt}
      PROMPT
    end

    private

    def profile
      lines = [ "Name: #{@user.name.presence || 'unknown'}" ]
      lines << "Born: #{@user.birth_year}" if @user.birth_year
      lines << "In their own words: #{@user.about_me}" if @user.about_me.present?
      lines << "Today: #{I18n.l(Date.current, locale: :en, format: :long)}"
      "## Profile\n" + lines.join("\n")
    end

    def areas
      rows = @user.active_life_areas.map do |la|
        parts = [ "- #{la.area_key}" ]
        parts << "rating #{la.rating}/10" if la.rating
        parts << "now: #{la.current_state.squish.truncate(300)}" if la.current_state.present?
        parts << "focus goal: #{la.focus_goal.squish.truncate(200)}" if la.focus_goal.present?
        parts.join(" | ")
      end
      "## Life areas (active)\n#{rows.join("\n")}" if rows.any?
    end

    def approaches
      choices = @user.approach_choices.to_a
      return if choices.empty?

      lines = choices.filter_map do |c|
        a = Approach.find(c.approach_key) or next
        case c.stance
        when "resonates" then "- FOLLOWS #{a.key}: #{a.principles}"
        when "curious" then "- CURIOUS ABOUT #{a.key}: #{a.principles}"
        when "rejected" then "- REJECTS #{a.key} (do not recommend)"
        end
      end
      "## Chosen frameworks\n#{lines.join("\n")}"
    end

    def memories
      scope = @user.memories.current.ordered
      scope = scope.where(area_key: [ nil, @focus_area ]).or(scope.where(pinned: true)) if @focus_area
      items = scope.limit(60).map { |m| "- [#{m.category}#{"/#{m.area_key}" if m.area_key}] #{m.content}" }
      "## Things you have learned about the person\n#{items.join("\n")}" if items.any?
    end

    def experiments
      items = @user.experiments.order(updated_at: :desc).limit(10).map do |e|
        line = "- #{e.status}: #{e.title} (#{e.area_key || 'general'})"
        line += " hypothesis: #{e.hypothesis.squish.truncate(150)}" if e.hypothesis.present?
        line += " learning: #{e.learning.squish.truncate(200)}" if e.learning.present?
        line
      end
      "## Experiments\n#{items.join("\n")}" if items.any?
    end

    def check_ins
      items = @user.check_ins.recent.limit(4).map do |c|
        parts = [ "- week of #{c.week_start}" ]
        parts << "ratings #{c.ratings.compact_blank.to_json}" if c.ratings.present?
        parts << "energy #{c.energy}" if c.energy
        parts << "went well: #{c.went_well.squish.truncate(200)}" if c.went_well.present?
        parts << "hard: #{c.challenges.squish.truncate(200)}" if c.challenges.present?
        parts << "learned: #{c.learned.squish.truncate(200)}" if c.learned.present?
        parts << "next focus: #{c.next_focus.squish.truncate(150)}" if c.next_focus.present?
        parts.join(" | ")
      end
      "## Recent weekly check-ins\n#{items.join("\n")}" if items.any?
    end

    def trends
      rows = @user.measurements.where(measured_at: 60.days.ago..).group(:metric_key, :label, :unit)
                  .pluck(:metric_key, :label, :unit, Arel.sql("AVG(value)"), Arel.sql("COUNT(*)"), Arel.sql("MAX(measured_at)"))
      return if rows.empty?

      lines = rows.map do |key, label, unit, avg, count, last|
        latest = @user.measurements.where(metric_key: key).recent.first
        flag = latest&.out_of_range? ? " OUT OF REFERENCE RANGE (#{latest.reference_low}-#{latest.reference_high})" : ""
        "- #{label.presence || key}: latest #{latest&.value&.to_f} #{unit}#{flag}, 60d avg #{avg.to_f.round(2)} (n=#{count}, last #{last.to_date})"
      end
      "## Measurements (last 60 days)\n#{lines.first(40).join("\n")}"
    end

    def insights
      items = @user.insights.visible.recent.limit(5).map { |i| "- #{i.title}: #{i.body.squish.truncate(200)}" }
      "## Patterns found earlier\n#{items.join("\n")}" if items.any?
    end

    def recent_entries
      scope = @user.entries.recent
      scope = scope.in_area(@focus_area) if @focus_area
      items = scope.limit(15).map { |e| "- #{e.occurred_at.to_date} [#{e.area_keys.join(',')}] #{e.body.squish.truncate(240)}" }
      "## Recent log entries\n#{items.join("\n")}" if items.any?
    end
  end
end
