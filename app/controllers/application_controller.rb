class ApplicationController < ActionController::Base
  around_action :switch_locale

  # Include the active locale in every generated URL so navigation, forms,
  # redirects and Turbo requests stay in the language the citizen selected.
  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale.to_s }
  end

  private

  def switch_locale(&action)
    locale = resolve_locale
    session[:locale] = locale.to_s
    I18n.with_locale(locale, &action)
  end

  def resolve_locale
    requested = params[:locale].to_s
    available = I18n.available_locales.map(&:to_s)
    selected = if available.include?(requested)
      requested
    elsif available.include?(session[:locale].to_s)
      session[:locale].to_s
    elsif available.include?(cookies[:locale].to_s)
      cookies[:locale].to_s
    else
      I18n.default_locale.to_s
    end
    cookies[:locale] = { value: selected, expires: 1.year.from_now }
    selected.to_sym
  end
end
