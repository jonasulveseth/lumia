class MeasurementsController < ApplicationController
  def index
    @summaries = current_user.measurements.group(:metric_key)
                             .pluck(:metric_key, Arel.sql("COUNT(*)"), Arel.sql("MAX(measured_at)"))
                             .sort_by { |_, _, last| last }.reverse
    @labels = current_user.measurements.where.not(label: nil).distinct.pluck(:metric_key, :label).to_h
    @measurement = current_user.measurements.new(measured_at: Time.current)
  end

  def show
    @metric_key = params[:id]
    @measurements = current_user.measurements.where(metric_key: @metric_key).recent
    raise ActiveRecord::RecordNotFound if @measurements.empty? && Metric.find(@metric_key).nil?
    @label = @measurements.first&.display_label || Metric.find(@metric_key).name
  end

  def create
    m = current_user.measurements.new(params.expect(measurement: %i[metric_key value measured_at]))
    if m.save
      redirect_back_or_to measurements_path, notice: t("flash.saved")
    else
      redirect_back_or_to measurements_path, alert: m.errors.full_messages.to_sentence
    end
  end

  def destroy
    m = current_user.measurements.find(params[:id])
    m.destroy
    redirect_back_or_to measurement_path(m.metric_key), status: :see_other
  end
end
