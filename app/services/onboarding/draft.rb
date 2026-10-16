module Onboarding
  # Profilutkastet som växer fram under intervjun (Conversation#profile_draft).
  # Allt som kommer från språkmodellen tvättas här: okända nycklar, områden och
  # ramverk som inte finns i katalogerna och värden utanför sina intervall
  # slängs, så att apply! och vyerna kan lita på formen.
  class Draft
    def self.sanitize(raw)
      raw = raw.is_a?(Hash) ? raw.deep_stringify_keys : {}
      areas = (raw["areas"].is_a?(Hash) ? raw["areas"] : {}).slice(*Area.keys).filter_map do |key, a|
        next unless a.is_a?(Hash)
        [ key, { "active" => a["active"] != false,
                 "rating" => integer(a["rating"], 1..10),
                 "current_state" => a["current_state"].to_s.strip.truncate(600),
                 "focus_goal" => a["focus_goal"].to_s.strip.truncate(300) } ]
      end.to_h
      approaches = (raw["approaches"].is_a?(Hash) ? raw["approaches"] : {})
                     .slice(*Approach.keys).select { |_, stance| stance.in?(ApproachChoice::STANCES) }
      memories = Array(raw["memories"]).filter_map do |m|
        content = (m.is_a?(Hash) ? m["content"] : m).to_s.strip
        next if content.blank?
        m = {} unless m.is_a?(Hash)
        { "content" => content.truncate(400),
          "category" => m["category"].presence_in(Memory::CATEGORIES) || "fact",
          "area_key" => m["area_key"].presence_in(Area.keys) }
      end.uniq { _1["content"] }.first(Interview::MAX_MEMORIES)

      { "summary" => raw["summary"].to_s.strip.truncate(2000),
        "birth_year" => integer(raw["birth_year"], 1900..Date.current.year),
        "coach_style" => raw["coach_style"].presence_in(Coaching.styles),
        "areas" => areas,
        "approaches" => approaches,
        "memories" => memories,
        "confidence" => integer(raw["confidence"], 0..10) || 0 }
    end

    def self.integer(value, range)
      number = Integer(value.to_s, exception: false) || Float(value.to_s, exception: false)&.round
      number if number && range.cover?(number)
    end

    def initialize(data)
      @data = data.presence || {}
    end

    def summary = @data["summary"].to_s
    def birth_year = @data["birth_year"]
    def coach_style = @data["coach_style"]
    def areas = @data["areas"] || {}
    def approaches = @data["approaches"] || {}
    def memories = @data["memories"] || []
    def confidence = @data["confidence"].to_i
    def empty? = summary.blank? && areas.empty? && approaches.empty?

    def active_areas = Area.all.filter_map { |area| (a = areas[area.key]) && a["active"] && [ area, a ] }
    def left_out_areas = Area.all.select { |area| areas.dig(area.key, "active") == false }

    # Det intervjuaren ännu inte vet, så att samtalet söker sig dit.
    def gaps
      gaps = []
      gaps << "what is going on in their life and what they want" if summary.blank?
      untouched = Area.keys - areas.keys
      gaps << "life areas not discussed yet: #{untouched.join(', ')}" if untouched.any?
      if active_areas.any? && active_areas.none? { |_, a| a["focus_goal"].present? }
        gaps << "a small focus goal for the areas that matter most to them"
      end
      gaps << "frameworks/methods they like or dislike" if approaches.empty?
      gaps << "how they want to be coached" unless coach_style
      gaps
    end

    def to_prompt
      return "(nothing yet)" if empty?

      lines = []
      lines << "Summary: #{summary}" if summary.present?
      lines << "Born: #{birth_year}" if birth_year
      lines << "Coaching style: #{coach_style}" if coach_style
      areas.each do |key, a|
        parts = [ "- #{key}", (a["active"] ? nil : "LEFT OUT"), ("#{a['rating']}/10" if a["rating"]),
                  a["current_state"].presence, ("goal: #{a['focus_goal']}" if a["focus_goal"].present?) ]
        lines << parts.compact.join(" | ")
      end
      lines << "Frameworks: #{approaches.map { "#{_1} #{_2}" }.join(', ')}" if approaches.any?
      lines.join("\n")
    end
  end
end
