module ChatProviders
  # OpenAI, Moonshot, OpenRouter, Mistral och andra med /v1/chat/completions.
  #
  # options[:reasoning_effort] skickas med om den är satt. Reasoning-modeller
  # räknar tankarna mot max_tokens, så utan "none" kan ett svar kapas innan
  # någon text alls hunnit skrivas (se InferenceConfig::PRESETS).
  class OpenaiCompatible < Base
    def chat(messages, temperature: 0.7, max_tokens: 2048, json: false, &block)
      payload = { model: model, messages: messages, stream: block_given?, temperature: temperature, max_tokens: max_tokens }
      payload[:response_format] = { type: "json_object" } if json
      payload[:reasoning_effort] = options[:reasoning_effort] if options[:reasoning_effort].present?

      text = +""
      finish_reason = nil
      post("/v1/chat/completions", payload) do |response|
        if block
          buffer = +""
          response.read_body do |chunk|
            buffer << chunk.force_encoding("UTF-8")
            while (line = buffer.slice!(/\A[^\n]*\n/))
              line = line.strip
              next unless line.start_with?("data:")
              data = line.delete_prefix("data:").strip
              next if data == "[DONE]" || data.empty?
              choice = JSON.parse(data).dig("choices", 0) || {}
              finish_reason = choice["finish_reason"] || finish_reason
              piece = choice.dig("delta", "content").to_s
              next if piece.empty?
              text << piece
              block.call(piece)
            end
          end
        else
          choice = JSON.parse(response.body).dig("choices", 0) || {}
          finish_reason = choice["finish_reason"]
          text = choice.dig("message", "content").to_s
        end
      end

      text = strip_thinking(text)
      # Ett kapat JSON-svar går inte att tolka, och ett kapat svar utan text
      # betyder att hela budgeten gick åt till modellens tankar.
      if finish_reason == "length" && (json || text.empty?)
        raise Ai::Error, "Svaret kapades vid max_tokens=#{max_tokens} (#{model}, #{text.length} tecken text)"
      end
      text
    end
  end
end
