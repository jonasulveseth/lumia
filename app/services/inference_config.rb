# Vilken modell som används, i prioritetsordning:
#   1. AiProvider markerad som standard i databasen
#   2. Rails credentials (inference: { provider:, base_url:, api_key:, primary:, lightweight: })
#      provider: nebius räcker med api_key – base_url och modell har standardvärden nedan.
#   3. Lokal Ollama (OLLAMA_BASE_URL / OLLAMA_MODEL i .env)
module InferenceConfig
  ROLES = %i[primary lightweight].freeze
  OLLAMA_BASE_URL = "http://localhost:11434"
  OLLAMA_MODEL = "qwen3.8:27b"

  # Leverantörer med kända standardvärden. base_url utan /v1 (providern lägger till /v1/chat/completions).
  PRESETS = {
    "nebius" => { base_url: "https://api.tokenfactory.nebius.com", model: "deepseek-ai/DeepSeek-V4.1-Flash-1017" }
  }.freeze

  module_function

  def build_provider(role = :primary)
    raise ArgumentError, "Okänd roll: #{role}" unless ROLES.include?(role.to_sym)

    if (record = provider_record)
      model = role.to_sym == :lightweight ? record.lightweight_model.presence || record.chat_model : record.chat_model
      klass = record.ollama? ? ChatProviders::Ollama : ChatProviders::OpenaiCompatible
      return klass.new(base_url: record.api_base_url, model: model, api_key: record.api_key)
    end

    creds = Rails.application.credentials.dig(:inference) || {}
    provider = creds[:provider].to_s
    preset = PRESETS[provider]

    # En extern leverantör utan nyckel faller tillbaka på lokal Ollama i stället för att ge 401.
    if provider.present? && provider != "ollama" && creds[:api_key].present?
      base_url = creds[:base_url].presence || preset&.dig(:base_url)
      model = creds[role.to_sym].presence || creds[:primary].presence || preset&.dig(:model)
      return ChatProviders::OpenaiCompatible.new(base_url: base_url, model: model, api_key: creds[:api_key])
    end

    ollama_creds = provider.in?(["", "ollama"]) ? creds : {}
    base_url = ollama_creds[:base_url].presence || ENV["OLLAMA_BASE_URL"].presence || OLLAMA_BASE_URL
    model = ollama_creds[role.to_sym].presence || ollama_creds[:primary].presence || ENV["OLLAMA_MODEL"].presence || OLLAMA_MODEL
    ChatProviders::Ollama.new(base_url: base_url, model: model)
  end

  def provider_record
    AiProvider.default
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
    nil
  end
end
