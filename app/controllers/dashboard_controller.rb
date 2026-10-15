class DashboardController < ApplicationController
  def show
    @life_areas = current_user.active_life_areas
    @experiments = current_user.experiments.running.order(:ends_on).limit(4)
    @insights = current_user.insights.visible.recent.limit(3)
    @entries = current_user.entries.recent.limit(5)
    @check_in = current_user.current_check_in
    @entry = current_user.entries.new
    @trend_metrics = current_user.measurements.where(measured_at: 30.days.ago..)
                                 .group(:metric_key).order(Arel.sql("COUNT(*) DESC")).limit(4).count.keys
  end
end
