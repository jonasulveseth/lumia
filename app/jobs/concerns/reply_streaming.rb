# Strömmar språkmodellens svar in i ett assistentmeddelande. Meddelandet
# broadcastar sig självt vid varje uppdatering, så texten växer fram på skärmen.
module ReplyStreaming
  extend ActiveSupport::Concern

  included do
    # Sekunder mellan uppdateringar av det strömmande svaret.
    class_attribute :broadcast_interval, default: 0.15
  end

  private

  def stream_reply(reply, messages, **opts)
    reply.update!(status: "streaming")
    buffer = +""
    last_push = Time.current
    text = Ai.chat(messages, **opts) do |chunk|
      buffer << chunk
      if Time.current - last_push >= broadcast_interval
        reply.update_columns(content: buffer.dup) # dup: annars delar attributet objekt med bufferten och slutsparningen ser ingen ändring
        reply.broadcast_replace_to reply.conversation
        last_push = Time.current
      end
    end
    # Ett tomt svar skulle lämna "tänker"-snurran kvar för alltid; låt jobbet visa felet i stället.
    raise Ai::Error, "Tomt svar från modellen" if text.blank?
    reply.update!(content: text, status: "done")
    text
  end
end
