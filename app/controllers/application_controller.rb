class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :require_onboarding

  private

  def switch_locale(&action)
    locale = Current.user&.locale || params[:locale].presence_in(%w[sv en]) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # Den som inte gått igenom onboarding hamnar där först – utan områden och
  # ramverk har coachen inget att utgå från.
  def require_onboarding
    return unless authenticated? && !Current.user.onboarded?
    redirect_to onboarding_path unless is_a?(OnboardingController) || is_a?(SessionsController)
  end

  # Allt användardata hämtas via Current.user – aldrig Model.find direkt.
  def current_user = Current.user
  helper_method :current_user
end
