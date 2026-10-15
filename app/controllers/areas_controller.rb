class AreasController < ApplicationController
  before_action :set_life_area, only: %i[show update]

  def index
    @life_areas = current_user.life_areas
  end

  def show
    @area = @life_area.area
    @entries = current_user.entries.in_area(@area.key).recent.limit(10)
    @experiments = current_user.experiments.where(area_key: @area.key).order(updated_at: :desc).limit(6)
    @memories = current_user.memories.current.where(area_key: @area.key).ordered.limit(10)
    @choices = current_user.approach_choices.index_by(&:approach_key)
    @metric_keys = current_user.measurements.where(area_key: @area.key).distinct.pluck(:metric_key)
    @entry = current_user.entries.new(area_keys: [ @area.key ])
  end

  def update
    @life_area.update!(params.expect(life_area: %i[rating current_state focus_goal active]))
    redirect_back_or_to area_path(@life_area), notice: t("flash.saved")
  end

  private

  def set_life_area
    current_user.ensure_life_areas!
    @life_area = current_user.life_areas.find_by!(area_key: params[:id])
  end
end
