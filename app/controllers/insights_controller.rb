class InsightsController < ApplicationController
  def index
    @insights = current_user.insights.visible.recent
  end

  def update
    current_user.insights.find(params[:id]).update!(status: params[:status].presence_in(Insight::STATUSES) || "new")
    redirect_to insights_path, status: :see_other
  end

  def generate
    PatternDetectionJob.perform_later(current_user)
    redirect_to insights_path, notice: t("insights.generating")
  end
end
