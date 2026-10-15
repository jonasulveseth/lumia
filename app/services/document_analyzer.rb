# Läser ett provsvar eller en journalkopia och sparar varje värde som
# Measurement, så att det syns i trender och går in i coachens kontext.
class DocumentAnalyzer
  MAX_CHARS = 20_000

  def initialize(document)
    @document = document
    @user = document.user
  end

  def call
    @document.update!(status: "processing", error_message: nil)
    text = extract_text
    raise Ai::Error, I18n.t("documents.errors.no_text") if text.blank?

    result = Ai.json(system: system_prompt, prompt: text.truncate(MAX_CHARS), max_tokens: 4096)
    taken_on = parse_date(result["date"]) || @document.taken_on || @document.created_at.to_date

    ActiveRecord::Base.transaction do
      @document.measurements.destroy_all
      Array(result["values"]).each { |v| create_measurement(v, taken_on) }
      @document.update!(extracted_text: text, summary: result["summary"], taken_on: taken_on, status: "done")
    end
  rescue StandardError => e
    @document.update!(status: "failed", error_message: e.message.truncate(250))
    raise
  end

  private

  def extract_text
    return @document.extracted_text if @document.extracted_text.present? && !@document.file.attached?
    return unless @document.file.attached?

    @document.file.open do |io|
      case @document.file.content_type
      when "application/pdf" then PDF::Reader.new(io.path).pages.map(&:text).join("\n")
      when %r{\Atext/} then File.read(io.path)
      end
    end.to_s.squeeze(" ")
  end

  def create_measurement(v, taken_on)
    value = v["value"].to_s.tr(",", ".")
    return unless value.match?(/\A-?\d+(\.\d+)?\z/)

    name = v["name"].to_s.strip.presence or return
    key = Metric.find(v["metric"].to_s) ? v["metric"].to_s : "lab_#{name.parameterize(separator: "_").tr("-", "_")}"
    @user.measurements.create!(
      metric_key: key, label: name, value: value.to_f, unit: v["unit"].presence,
      reference_low: numeric(v["reference_low"]), reference_high: numeric(v["reference_high"]),
      area_key: Area.keys.include?(v["area"].to_s) ? v["area"] : "health",
      measured_at: (parse_date(v["date"]) || taken_on).to_time.change(hour: 12), source: @document
    )
  end

  def numeric(raw)
    raw = raw.to_s.tr(",", ".")
    raw.match?(/\A-?\d+(\.\d+)?\z/) ? raw.to_f : nil
  end

  def parse_date(raw)
    Date.parse(raw.to_s)
  rescue Date::Error
    nil
  end

  def system_prompt
    <<~PROMPT
      You read a medical lab report or health record for a personal coaching app. Return ONLY JSON:
      {
        "date": "YYYY-MM-DD" (sample date if stated, else null),
        "summary": "3-6 sentences in #{@user.locale == 'en' ? 'English' : 'Swedish'}: what was measured, what stands out, which values are outside reference. Neutral tone, no diagnosis.",
        "values": [{"name": "name as written (e.g. LDL-kolesterol)", "metric": known key or null, "value": number,
                    "unit": "unit", "reference_low": number or null, "reference_high": number or null,
                    "date": "YYYY-MM-DD" or null, "area": "health" or "nutrition"}]
      }
      Known metric keys you may map to: #{Metric.all.map(&:key).join(', ')}.
      Use a dot as decimal separator. Skip values that are not numeric.
    PROMPT
  end
end
