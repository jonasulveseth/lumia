require "test_helper"

class ChatProviders::OpenaiCompatibleTest < ActiveSupport::TestCase
  URL = "https://llm.example/v1/chat/completions".freeze

  def provider(options = {})
    ChatProviders::OpenaiCompatible.new(base_url: "https://llm.example", model: "m", api_key: "k", options: options)
  end

  def completion(content, finish_reason: "stop")
    { choices: [ { finish_reason: finish_reason, message: { role: "assistant", content: content } } ] }.to_json
  end

  test "sends reasoning_effort only when the provider is configured with it" do
    stub_request(:post, URL).to_return(body: completion("Hej"))

    provider.chat([ { role: "user", content: "Hej" } ])
    assert_requested(:post, URL) { |req| !JSON.parse(req.body).key?("reasoning_effort") }

    provider(reasoning_effort: "none").chat([ { role: "user", content: "Hej" } ])
    assert_requested(:post, URL) { |req| JSON.parse(req.body)["reasoning_effort"] == "none" }
  end

  test "raises when a JSON answer is cut off at max_tokens" do
    stub_request(:post, URL).to_return(body: completion('{"summary": "Du är', finish_reason: "length"))

    error = assert_raises(Ai::Error) { provider.chat([ { role: "user", content: "x" } ], json: true, max_tokens: 3000) }
    assert_match "max_tokens=3000", error.message
  end

  test "raises when the whole budget went to reasoning and no text came back" do
    stub_request(:post, URL).to_return(body: completion("", finish_reason: "length"))

    assert_raises(Ai::Error) { provider.chat([ { role: "user", content: "x" } ]) }
  end

  test "keeps a cut-off plain text answer" do
    stub_request(:post, URL).to_return(body: completion("Början på ett långt svar", finish_reason: "length"))

    assert_equal "Början på ett långt svar", provider.chat([ { role: "user", content: "x" } ])
  end

  test "streams the pieces and returns the whole text" do
    body = [ { choices: [ { delta: { content: "Hej " } } ] }, { choices: [ { delta: { content: "där" }, finish_reason: "stop" } ] } ]
             .map { "data: #{_1.to_json}\n\n" }.join + "data: [DONE]\n\n"
    stub_request(:post, URL).to_return(body: body)

    pieces = []
    assert_equal "Hej där", provider.chat([ { role: "user", content: "x" } ]) { pieces << _1 }
    assert_equal [ "Hej ", "där" ], pieces
  end

  test "nebius gets reasoning turned off, other hosts are left alone" do
    assert_equal({ reasoning_effort: "none" }, InferenceConfig.options_for("https://api.tokenfactory.nebius.com"))
    assert_equal({}, InferenceConfig.options_for("https://api.openai.com"))
  end
end
