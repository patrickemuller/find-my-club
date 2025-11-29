class Callbacks::StripeController < ApplicationController
  def callback
    # Handle OAuth callback
    if params[:code].present?
      stripe_account_id = StripeService.complete_onboarding(params[:code])

      club = Club.find(params[:state])
      account = StripeService.retrieve_account(stripe_account_id)

      club.update(
        stripe_account_id: stripe_account_id,
        stripe_account_status: account.charges_enabled ? "complete" : "pending"
      )

      redirect_to club_payments_path(club), notice: "Stripe account connected successfully!"
    else
      redirect_to my_clubs_path, alert: "Failed to connect Stripe account."
    end
  end

  private

  def set_club
    @club = Club.friendly.find(params[:club_id] || params[:state])
  end
end
