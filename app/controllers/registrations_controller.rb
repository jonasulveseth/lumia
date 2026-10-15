class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: t("sessions.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: %i[name email_address password]))
    @user.locale = I18n.locale.to_s
    if @user.save
      @user.ensure_life_areas!
      start_new_session_for @user
      redirect_to onboarding_path
    else
      render :new, status: :unprocessable_entity
    end
  end
end
