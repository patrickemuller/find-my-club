# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
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
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :strava_url, :trailforks_url, :outside_url, :athlinks_url ])
  end
end
