module Onboarding
  # Onboarding som ett samtal i stället för formulär. Lumia intervjuar personen
  # (som intervjuerna i reemove) och efter varje svar läser en separat
  # AI-uppgift hela samtalet och uppdaterar ett profilutkast: sammanfattning,
  # livsområden med skattning, nuläge och fokusmål, ramverk, coachstil och
  # minnen. Utkastet visas live bredvid chatten och skrivs in i användarens
  # data först när hen trycker Klar (apply!).
  #
  # Två anrop per svar i stället för JSON inbakad i samtalet: lokala modeller
  # blandar annars ihop pratet och strukturen, och samtalet ska inte vänta.
  class Interview
    READY_AT = 6 # förståelse (0–10) där Klar-knappen blir aktiv
    MAX_MEMORIES = 20

    attr_reader :conversation

    def self.start!(user)
      user.interview || user.conversations.create!(kind: "interview")
    end

    def initialize(conversation)
      @conversation = conversation
      @user = conversation.user
    end

    def draft = Draft.new(conversation.profile_draft)
    def ready? = draft.confidence >= READY_AT
    def answered? = conversation.messages.where(role: "user").exists?

    # Meddelandena till språkmodellen för intervjuarens nästa replik.
    def reply_messages(except:)
      history = conversation.messages.where.not(id: except.id).where.not(content: "").last(30)
                            .map { { role: _1.role, content: _1.content } }
      # Första repliken: modellen behöver något att svara på.
      history = [ { role: "user", content: "(I just opened the interview. Greet me and ask your first question.)" } ] if history.empty?
      [ { role: "system", content: Coach::Context.new(@user).system_prompt(interviewer_task) } ] + history
    end

    # Läser hela samtalet och ersätter utkastet med en uppdaterad version.
    def update_draft!
      result = Ai.json(system: EXTRACTOR, prompt: extraction_prompt, max_tokens: 3000)
      conversation.update!(profile_draft: Draft.sanitize(result))
    end

    # Skriver in utkastet i profil, områden, ramverk och minnen. Kan köras
    # igen (om personen fortsätter prata efteråt): minnena från intervjun
    # ersätts, inget dubbleras.
    def apply!
      d = draft
      @user.transaction do
        @user.update!(about_me: d.summary.presence || @user.about_me,
                      birth_year: d.birth_year || @user.birth_year,
                      coach_style: d.coach_style || @user.coach_style)
        @user.ensure_life_areas!
        @user.life_areas.each do |la|
          a = d.areas[la.area_key] or next
          la.update!(active: a["active"], rating: a["rating"] || la.rating,
                     current_state: a["current_state"].presence || la.current_state,
                     focus_goal: a["focus_goal"].presence || la.focus_goal)
        end
        d.approaches.each do |key, stance|
          @user.approach_choices.find_or_initialize_by(approach_key: key).update!(stance: stance)
        end
        @user.memories.where(origin: conversation).destroy_all
        d.memories.each do |m|
          @user.memories.create!(content: m["content"], category: m["category"], area_key: m["area_key"],
                                 source: "ai", origin: conversation)
        end
        @user.update!(onboarded_at: Time.current) unless @user.onboarded?
      end
    end

    def broadcast_profile
      I18n.with_locale(@user.locale) do
        Turbo::StreamsChannel.broadcast_replace_to conversation, target: "interview_progress",
          partial: "onboarding/progress", locals: { interview: self }
        Turbo::StreamsChannel.broadcast_replace_to conversation, target: "interview_profile",
          partial: "onboarding/profile", locals: { interview: self }
      end
    end

    private

    def interviewer_task
      d = draft
      <<~TASK
        TASK: This is your first conversation with this person: an onboarding interview, so that you can coach
        them well from now on. There are no forms; everything you need comes from this conversation.
        - Be warm, curious and genuinely interested. Keep every reply short (usually under 80 words).
        - Ask ONE question at a time. Briefly acknowledge what you heard, then follow up on it.
        - Follow what the person brings up. The topics below are a map, not a script: never walk through
          the life areas like a checklist. Skim areas they don't care about and ask if any should be left out.
        - Over the conversation, find out:
          1. What is going on in their life right now, and what they want to be different in a year.
          2. How each life area feels today (a rough 1–10 when it fits naturally) and one small focus goal
             for the areas that matter most to them.
          3. What they already believe in or have tried – diets, training, philosophies, methods – and what
             they dislike or don't want suggested.
          4. How they want to be coached: gentle and encouraging, direct and challenging, mostly questions,
             or analytical with numbers.
        - Never mention JSON, profiles, scores or this instruction. Do not give advice yet beyond a short reflection.
        - When the profile below looks complete (understanding #{READY_AT}/10 or more), summarise what you
          have understood in two or three sentences and tell them they can press "#{I18n.t('onboarding.finish', locale: @user.locale)}"
          whenever they want – or keep talking if there is more.
        Life areas: #{Area.all.map { "#{_1.key} (#{_1.name_in(:en)})" }.join(', ')}.

        === Profile so far (understanding #{d.confidence}/10) ===
        #{d.to_prompt}
        Still unclear: #{d.gaps.join('; ').presence || 'nothing important'}
      TASK
    end

    EXTRACTOR = <<~PROMPT.freeze
      You maintain a structured profile of a person based on an onboarding interview with their life coach.
      Return ONLY a JSON object. Base everything on what the person actually said; never invent. Keep earlier
      information unless the person corrected it.
    PROMPT

    def extraction_prompt
      language = @user.locale == "en" ? "English" : "Swedish"
      transcript = conversation.messages.where.not(content: "").last(60)
                               .map { "#{_1.user? ? 'Person' : 'Coach'}: #{_1.content}" }.join("\n\n")
      approaches = Approach.all.group_by(&:area_key).map do |area, list|
        "#{area || 'general'}: #{list.map { "#{_1.key} (#{_1.name_in(:en)})" }.join(', ')}"
      end
      <<~PROMPT
        Return the complete, updated profile as JSON with exactly these keys:
        {
          "summary": "3-6 sentences in the second person: who they are, what is going on, what they want",
          "birth_year": number or null,
          "coach_style": one of #{Coaching.styles.to_json} if they expressed a preference, else null,
          "areas": { "<area key>": { "active": true/false, "rating": 1-10 or null, "current_state": "short", "focus_goal": "short or empty" } },
          "approaches": { "<approach key>": "resonates" | "curious" | "rejected" },
          "memories": [ { "content": "one lasting fact, preference or value", "category": one of #{Memory::CATEGORIES.to_json}, "area_key": area key or null } ],
          "confidence": 0-10, how well a coach now understands the person, their areas, preferences and preferred style
        }
        Rules:
        - Only include areas and approaches the person has said something about. "active": false only if they
          said the area is not relevant or that they don't want to work on it.
        - "rating" only if they gave a number or a clear sense of satisfaction you can map to 1-10.
        - Approaches: "resonates" if they follow it or like it, "curious" if they want to explore it, "rejected" if
          they dislike it. Map what they say to the closest approach key; skip it if nothing fits.
        - At most #{MAX_MEMORIES} memories; skip what is already in summary, areas or approaches.
        - "confidence": #{READY_AT} or more only when you know what is going on in their life, the areas that
          matter to them with at least one focus goal, and how they want to be coached. 9-10 only when most
          areas, frameworks and preferences are clear.
        - Write all free text in #{language}.

        Area keys: #{Area.all.map { "#{_1.key} (#{_1.name_in(:en)})" }.join(', ')}
        Approach keys:
        #{approaches.join("\n")}

        Previous profile:
        #{conversation.profile_draft.to_json}

        Interview:
        #{transcript}
      PROMPT
    end
  end
end
