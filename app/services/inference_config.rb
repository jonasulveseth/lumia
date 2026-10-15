# Vilken modell som används, i prioritetsordning:
#   1. AiProvider markerad som standard i databasen
#   2. Rails credentials (inference: { provider:, base_url:, api_key:, primary:, lightweight: })
#   3. Lokal Ollama (OLLAMA_BASE_URL / OLLAMA_MODEL i .env)
module InferenceConfig
  ROLES = %i[primary lightweight].freeze
  OLLAMA_BASE_URL = "http://localhost:11434"
  OLLAMA_MODEL = "qwen3.8:27b"

  module_function

  def build_provider(role = :primary)
    raise ArgumentError, "Okänd roll: #{role}" unless ROLES.include?(role.to_sym)

    if (record = provider_record)
      model = role.to_sym == :lightweight ? record.lightweight_model.presence || record.chat_model : record.chat_model
      klass = record.ollama? ? ChatProviders::Ollama : ChatProviders::OpenaiCompatible
      return klass.new(base_url: record.api_base_url, model: model, api_key: record.api_key)
    end

    creds = Rails.application.credentials.dig(:inference) || {}
    base_url = creds[:base_url].presence || ENV["OLLAMA_BASE_URL"].presence || OLLAMA_BASE_URL
    model = creds[role.to_sym].presence || creds[:primary].presence || ENV["OLLAMA_MODEL"].presence || OLLAMA_MODEL

    if creds[:provider].present? && creds[:provider] != "ollama"
      ChatProviders::OpenaiCompatible.new(base_url: base_url, model: model, api_key: creds[:api_key])
    else
      ChatProviders::Ollama.new(base_url: base_url, model: model)
    end
  end

  def provider_record
    AiProvider.default
  rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
    nil
  end
end
