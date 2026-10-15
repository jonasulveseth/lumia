module ChatProviders
  class Ollama < Base
    def chat(messages, temperature: 0.7, max_tokens: 2048, json: false, &block)
      payload = {
        model: model,
        messages: messages,
        stream: block_given?,
        think: false,
        options: { temperature: temperature, num_predict: max_tokens, num_ctx: options.fetch(:num_ctx, 32_768) }
      }
      payload[:format] = "json" if json

      text = +""
      post("/api/chat", payload) do |response|
        if block
          buffer = +""
          response.read_body do |chunk|
            buffer << chunk.force_encoding("UTF-8")
            while (line = buffer.slice!(/\A[^\n]*\n/))
              next if line.strip.empty?
              data = JSON.parse(line)
              piece = data.dig("message", "content").to_s
              next if piece.empty?
              text << piece
              block.call(piece)
            end
          end
        else
          text = JSON.parse(response.body).dig("message", "content").to_s
        end
      end
      strip_thinking(text)
    end
  end
end
