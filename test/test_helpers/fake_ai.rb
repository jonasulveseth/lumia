# Ersätter språkmodellen i tester. Svaren köas med FakeAi.respond_with och
# returneras i ordning; tom kö ger ett neutralt svar.
class FakeAi
  class << self
    def responses = (@responses ||= [])
    def calls = (@calls ||= [])
    def respond_with(*texts) = responses.concat(texts.map { _1.is_a?(String) ? _1 : _1.to_json })
    # Körs före varje strömmad bit, t.ex. för att flytta klockan i tester.
    attr_accessor :before_chunk
    def reset! = (@responses = []; @calls = []; @before_chunk = nil)
  end

  def chat(messages, **opts, &block)
    self.class.calls << { messages: messages, opts: opts }
    text = self.class.responses.shift || (opts[:json] ? "{}" : "Fint jobbat!")
    text.scan(/\S+\s*/).each_with_index { |piece, i| self.class.before_chunk&.call(i); block.call(piece) } if block
    text
  end
end

InferenceConfig.define_singleton_method(:build_provider) { |*| FakeAi.new }
