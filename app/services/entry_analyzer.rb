# Läser en loggpost och plockar ut: vilka områden den rör, mätvärden som
# nämns ("sov 6 timmar", "sprang 5 km på 30 min") och bestående fakta om
# personen som Lumia bör komma ihåg.
class EntryAnalyzer
  def initialize(entry)
    @entry = entry
    @user = entry.user
  end

  def call
    result = Ai.json(system: system_prompt, prompt: @entry.body, role: :lightweight)

    areas = Array(result["areas"]).map(&:to_s) & Area.keys
    kind = Entry::KINDS.include?(result["kind"].to_s) ? result["kind"] : @entry.kind

    ActiveRecord::Base.transaction do
      @entry.update!(area_keys: areas.presence || @entry.area_keys, kind: kind, processed_at: Time.current)
      # Idempotent: en omanalys ersätter postens mätvärden i stället för att dubblera dem.
      @user.measurements.where(source: @entry).delete_all
      create_measurements(result["measurements"])
      create_memories(result["memories"])
    end
  end

  private

  def create_measurements(items)
    Array(items).each do |m|
      key = m["metric"].to_s
      next unless (metric = Metric.find(key))
      value = m["value"].to_s.tr(",", ".").to_f
      next unless value.between?(metric.min.to_f, metric.max.to_f)

      @user.measurements.create!(metric_key: key, value: value, measured_at: @entry.occurred_at, source: @entry)
    end
  end

  def create_memories(items)
    existing = @user.memories.current.pluck(:content).map(&:downcase)
    Array(items).first(3).each do |m|
      content = m["content"].to_s.strip
      next if content.blank? || existing.include?(content.downcase)
      category = Memory::CATEGORIES.include?(m["category"]) ? m["category"] : "fact"
      area = Area.keys.include?(m["area"].to_s) ? m["area"] : nil
      @user.memories.create!(content: content, category: category, area_key: area, origin: @entry)
    end
  end

  def system_prompt
    known = @user.memories.current.ordered.limit(40).pluck(:content).map { |c| "- #{c}" }.join("\n")
    <<~PROMPT
      You analyse one personal log entry for a life-coaching app. Return ONLY a JSON object:
      {
        "areas": [one or more of: #{Area.keys.join(', ')}],
        "kind": one of #{Entry::KINDS.join(', ')},
        "measurements": [{"metric": key, "value": number}],
        "memories": [{"content": "...", "category": one of #{Memory::CATEGORIES.join(', ')}, "area": area key or null}]
      }
      Allowed metric keys (with units): #{Metric.all.map { |m| "#{m.key} (#{m.unit})" }.join(', ')}.
      Only include measurements explicitly stated for the day of the entry. Convert units to the listed ones.
      Memories: only durable, useful facts about the person (preferences, values, constraints, health facts,
      recurring patterns) – not one-off events. Write them in the same language as the entry, in third person,
      short. Skip anything already known:
      #{known.presence || '(nothing yet)'}
      Return empty arrays when nothing applies.
    PROMPT
  end
end
