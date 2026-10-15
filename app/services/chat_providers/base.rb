module ChatProviders
  # Gemensamt gränssnitt: chat(messages) med en lista { role:, content: }.
  # Med block strömmas texten bit för bit; utan block returneras hela svaret.
  class Base
    attr_reader :base_url, :model, :api_key, :options

    def initialize(base_url:, model:, api_key: nil, options: {})
      @base_url = base_url.to_s.chomp("/")
      @model = model
      @api_key = api_key
      @options = options
    end

    def chat(messages, temperature: 0.7, max_tokens: 2048, json: false, &block)
      raise NotImplementedError
    end

    private

    def post(path, payload, read_timeout: 180)
      uri = URI("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = read_timeout

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{api_key}" if api_key.present?
      request.body = payload.to_json

      http.request(request) do |response|
        raise Ai::Error, "#{self.class.name} #{response.code}: #{response.body.to_s.truncate(300)}" unless response.code == "200"
        yield response
      end
    end

    # Reasoning-modeller lägger ibland tankarna i texten.
    def strip_thinking(text)
      text.to_s.gsub(%r{<think>.*?</think>}m, "").strip
    end
  end
end
