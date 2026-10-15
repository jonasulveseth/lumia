class CreateLumiaCore < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.string :name
      t.string :locale, null: false, default: "sv"
      t.integer :birth_year
      # Hur coachen pratar: gentle, direct, socratic, analytical (se Coaching::STYLES)
      t.string :coach_style, null: false, default: "gentle"
      t.text :about_me
      t.datetime :onboarded_at
    end

    # AI-providers, samma modell som i reemove: byts från databasen utan deploy.
    create_table :ai_providers do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :provider_type, null: false, default: "ollama"
      t.string :api_base_url, null: false
      t.text :api_key
      t.string :chat_model
      t.string :lightweight_model
      t.boolean :is_default, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    # Ett livsområde som användaren har aktiverat. Själva områdena
    # (kropp, kost, sinne …) definieras i config/lumia/areas.yml.
    create_table :life_areas do |t|
      t.references :user, null: false, foreign_key: true
      t.string :area_key, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.integer :rating # 1–10, hur nöjd man är just nu
      t.text :current_state # nulägesbild med egna ord
      t.text :focus_goal
      t.timestamps
      t.index %i[user_id area_key], unique: true
    end

    # Vilka skolor/ramverk användaren resonerar med. Katalogen ligger i
    # config/lumia/approaches.yml — ramverket är samma för alla, innehållet väljs här.
    create_table :approach_choices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :approach_key, null: false
      t.string :stance, null: false, default: "resonates" # resonates, curious, rejected
      t.text :note
      t.timestamps
      t.index %i[user_id approach_key], unique: true
    end

    # Den universella inkorgen: allt man skriver, säger eller loggar.
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.string :kind, null: false, default: "note"
      t.string :area_keys, array: true, null: false, default: []
      t.string :source, null: false, default: "manual"
      t.datetime :occurred_at, null: false
      t.datetime :processed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
      t.index %i[user_id occurred_at]
    end

    # Uppladdade provsvar, journalkopior och liknande.
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :kind, null: false, default: "lab_result"
      t.date :taken_on
      t.text :extracted_text
      t.text :summary
      t.string :status, null: false, default: "pending" # pending, processing, done, failed
      t.string :error_message
      t.timestamps
    end

    # Ett mätvärde över tid: sömn, vikt, humör, LDL, HbA1c …
    create_table :measurements do |t|
      t.references :user, null: false, foreign_key: true
      t.string :metric_key, null: false
      t.string :label
      t.decimal :value, precision: 12, scale: 3, null: false
      t.string :unit
      t.decimal :reference_low, precision: 12, scale: 3
      t.decimal :reference_high, precision: 12, scale: 3
      t.string :area_key
      t.datetime :measured_at, null: false
      t.references :source, polymorphic: true
      t.timestamps
      t.index %i[user_id metric_key measured_at]
    end

    # Veckans reflektion.
    create_table :check_ins do |t|
      t.references :user, null: false, foreign_key: true
      t.date :week_start, null: false
      t.jsonb :ratings, null: false, default: {} # area_key => 1–10
      t.integer :energy
      t.text :went_well
      t.text :challenges
      t.text :learned
      t.text :next_focus
      t.text :coach_reply
      t.timestamps
      t.index %i[user_id week_start], unique: true
    end

    # "Vad testar jag nu? Vad lärde jag mig?"
    create_table :experiments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :area_key
      t.string :approach_key
      t.string :title, null: false
      t.text :hypothesis
      t.string :status, null: false, default: "running" # planned, running, completed, abandoned
      t.date :starts_on
      t.date :ends_on
      t.text :outcome
      t.text :learning
      t.integer :success_rating
      t.timestamps
    end

    # Det Lumia har lärt sig om dig. Alltid synligt och redigerbart.
    create_table :memories do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :category, null: false, default: "fact"
      t.string :area_key
      t.string :source, null: false, default: "ai"
      t.references :origin, polymorphic: true
      t.boolean :pinned, null: false, default: false
      t.datetime :archived_at
      t.timestamps
    end

    # Mönster tvärs över områden.
    create_table :insights do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.string :kind, null: false, default: "pattern" # pattern, correlation, suggestion
      t.string :area_keys, array: true, null: false, default: []
      t.jsonb :evidence, null: false, default: {}
      t.string :status, null: false, default: "new" # new, useful, dismissed
      t.timestamps
    end

    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :area_key
      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false, default: ""
      t.string :status, null: false, default: "done" # pending, streaming, done, failed
      t.timestamps
    end
  end
end
