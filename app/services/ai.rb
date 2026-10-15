# Ingången till språkmodellen för resten av appen.
#
#   Ai.chat(messages)                 # => hela svaret som text
#   Ai.chat(messages) { |chunk| … }   # strömmar
#   Ai.json(system:, prompt:)         # => Hash, tolkad ur modellens JSON-svar
module Ai
  class Error < StandardError; end

  module_function

  def chat(messages, role: :primary, **opts, &block)
    InferenceConfig.build_provider(role).chat(messages, **opts, &block)
  end

  def json(system:, prompt:, role: :primary, max_tokens: 2048)
    text = chat([ { role: "system", content: system }, { role: "user", content: prompt } ],
                role: role, json: true, temperature: 0.2, max_tokens: max_tokens)
    parse_json(text)
  end

  # Tål kodstaket och text runt JSON-objektet.
  def parse_json(text)
    cleaned = text.to_s.gsub(/```(?:json)?/i, "").strip
    JSON.parse(cleaned)
  rescue JSON::ParserError
    match = cleaned.match(/\{.*\}/m)
    match ? JSON.parse(match[0]) : raise(Error, "Kunde inte tolka JSON från modellen: #{text.to_s.truncate(200)}")
  end
end
