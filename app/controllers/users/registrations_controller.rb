# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  def create
    super do |resource|
      if resource.persisted? && session[:pending_invitation_token].present?
        invitation = ClubInvitation.find_by(token: session[:pending_invitation_token])
        if invitation&.can_accept?
          invitation.accept!(resource)
          session.delete(:pending_invitation_token)
          flash[:notice] = "Account created and you've joined #{invitation.club.name}!"
        end
      end
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone_number, :country_code ])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone_number, :country_code, :avatar, :strava_url, :trailforks_url, :outside_url, :athlinks_url ])
  end

  def after_update_path_for(resource)
    edit_user_registration_path(resource)
  end
end
