module ChatProviders
  # OpenAI, Moonshot, OpenRouter, Mistral och andra med /v1/chat/completions.
  class OpenaiCompatible < Base
    def chat(messages, temperature: 0.7, max_tokens: 2048, json: false, &block)
      payload = { model: model, messages: messages, stream: block_given?, temperature: temperature, max_tokens: max_tokens }
      payload[:response_format] = { type: "json_object" } if json

      text = +""
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
              piece = JSON.parse(data).dig("choices", 0, "delta", "content").to_s
              next if piece.empty?
              text << piece
              block.call(piece)
            end
          end
        else
          text = JSON.parse(response.body).dig("choices", 0, "message", "content").to_s
        end
      end
      strip_thinking(text)
    end
  end
end
