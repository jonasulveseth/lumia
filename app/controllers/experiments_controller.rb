class ExperimentsController < ApplicationController
  before_action :set_experiment, only: %i[edit update destroy]

  def index
    @active = current_user.experiments.active.order(:ends_on)
    @finished = current_user.experiments.finished.order(updated_at: :desc)
  end

  def new
    @experiment = current_user.experiments.new(area_key: params[:area], status: "running",
                                               starts_on: Date.current, ends_on: 14.days.from_now.to_date,
                                               title: params[:title], hypothesis: params[:hypothesis])
  end

  def create
    @experiment = current_user.experiments.new(experiment_params)
    if @experiment.save
      redirect_to experiments_path, notice: t("experiments.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @experiment.update(experiment_params)
      redirect_to experiments_path, notice: t("flash.saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @experiment.destroy
    redirect_to experiments_path, status: :see_other, notice: t("flash.deleted")
  end

  private

  def set_experiment
    @experiment = current_user.experiments.find(params[:id])
  end

  def experiment_params
    params.expect(experiment: %i[title hypothesis area_key approach_key status starts_on ends_on outcome learning success_rating])
  end
end
