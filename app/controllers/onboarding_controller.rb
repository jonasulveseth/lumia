# Fyra korta steg: du själv → dina områden → dina ramverk → klart.
# Allt går att ändra senare; poängen är att coachen har något att utgå från.
class OnboardingController < ApplicationController
  STEPS = %w[profile areas approaches].freeze

  before_action :set_step

  def show
    current_user.ensure_life_areas!
    @life_areas = current_user.life_areas
    @choices = current_user.approach_choices.index_by(&:approach_key)
  end

  def update
    case @step
    when "profile"
      current_user.update!(params.expect(user: %i[name birth_year about_me coach_style locale]))
    when "areas"
      attrs = params.fetch(:areas, {})
      current_user.life_areas.each do |la|
        a = attrs[la.area_key] || {}
        la.update!(active: a[:active] == "1", rating: a[:rating].presence, focus_goal: a[:focus_goal].presence || la.focus_goal)
      end
    when "approaches"
      params.fetch(:approaches, {}).each do |key, stance|
        next unless Approach.find(key)
        if stance.in?(ApproachChoice::STANCES)
          current_user.approach_choices.find_or_initialize_by(approach_key: key).update!(stance: stance)
        else
          current_user.approach_choices.where(approach_key: key).destroy_all
        end
      end
      current_user.update!(onboarded_at: Time.current) unless current_user.onboarded?
      return redirect_to root_path, notice: t("onboarding.done")
    end

    redirect_to onboarding_path(STEPS[STEPS.index(@step) + 1])
  end

  private

  def set_step
    @step = params[:step].presence_in(STEPS) || STEPS.first
    @step_index = STEPS.index(@step)
  end
end
