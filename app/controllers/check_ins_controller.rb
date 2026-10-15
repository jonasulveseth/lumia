class CheckInsController < ApplicationController
  before_action :set_check_in, only: %i[show edit update]

  def index
    @check_ins = current_user.check_ins.recent
  end

  def new
    if (existing = current_user.current_check_in)
      return redirect_to edit_check_in_path(existing)
    end
    @check_in = current_user.check_ins.new(ratings: current_user.active_life_areas.to_h { [ _1.area_key, _1.rating ] })
  end

  def create
    @check_in = current_user.check_ins.new(check_in_params)
    save_and_reply(:new)
  end

  def show
  end

  def edit
  end

  def update
    @check_in.assign_attributes(check_in_params)
    save_and_reply(:edit)
  end

  private

  def save_and_reply(template)
    if @check_in.save
      @check_in.update_column(:coach_reply, nil)
      CheckInReplyJob.perform_later(@check_in)
      redirect_to @check_in, notice: t("check_ins.saved")
    else
      render template, status: :unprocessable_entity
    end
  end

  def set_check_in
    @check_in = current_user.check_ins.find(params[:id])
  end

  def check_in_params
    permitted = params.expect(check_in: [ :energy, :went_well, :challenges, :learned, :next_focus, ratings: Area.keys ])
    permitted[:ratings] = permitted[:ratings].to_h.compact_blank.transform_values(&:to_i) if permitted[:ratings]
    permitted
  end
end
