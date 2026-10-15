class SettingsController < ApplicationController
  def show
  end

  def update
    if current_user.update(params.expect(user: %i[name email_address birth_year about_me coach_style locale]))
      redirect_to settings_path, notice: t("flash.saved", locale: current_user.locale)
    else
      render :show, status: :unprocessable_entity
    end
  end
end
