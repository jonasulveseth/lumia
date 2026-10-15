class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :life_areas, -> { order(:position) }, dependent: :destroy
  has_many :approach_choices, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :measurements, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  has_many :experiments, dependent: :destroy
  has_many :memories, dependent: :destroy
  has_many :insights, dependent: :destroy
  has_many :conversations, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :locale, inclusion: { in: %w[sv en] }
  validates :coach_style, inclusion: { in: Coaching.styles }

  def onboarded? = onboarded_at.present?
  def first_name = name.to_s.split.first.presence

  def active_life_areas = life_areas.where(active: true)

  # Sätter upp alla områden som rader så att man kan slå på/av dem.
  def ensure_life_areas!
    Area.all.each_with_index do |area, i|
      life_areas.find_or_create_by!(area_key: area.key) { |la| la.position = i }
    end
  end

  def life_area(key) = life_areas.find_by(area_key: key.to_s)

  def chosen_approaches(stance: "resonates")
    keys = approach_choices.where(stance: stance).pluck(:approach_key)
    Approach.all.select { |a| keys.include?(a.key) }
  end

  def current_check_in = check_ins.find_by(week_start: Date.current.beginning_of_week)
end
