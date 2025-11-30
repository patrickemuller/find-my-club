class Clubs::StripeAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_club
  before_action :authorize_owner!

  def new
    # Show connect Stripe page
  end

  def show
    # Always verify if the Club is ready to receive charges
    stripe_account = Stripe::Account.retrieve(@club.stripe_account_id)
    @club.update(
      stripe_account_status: stripe_account.charges_enabled ? "complete" : "pending"
    )
  end

  def create
    # Always set the integration as pending before initializing the connection
    stripe_oauth_link = Integrations::Stripe::Authentication.connect_oauth_uri(@club)
    @club.update(stripe_account_status: "pending")

    redirect_to stripe_oauth_link, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to club_payments_path(@club), alert: "Failed to connect Stripe account."
  end

  def callback
    # Handle OAuth callback
    if params[:code].present?
      response = Integrations::Stripe::Authentication.get_token(params, type: "authorization_code")
      stripe_account = Stripe::Account.retrieve(response.stripe_user_id)

      @club.update(
        stripe_account_id: response.stripe_user_id,
        stripe_account_status: stripe_account.charges_enabled ? "complete" : "pending"
      )

      redirect_to club_payments_path(@club), notice: "Stripe account connected successfully!"
    else
      redirect_to club_payments_path(@club), alert: "Failed to connect Stripe account."
    end
  end

  def destroy
    @club.update(stripe_account_id: nil, stripe_account_status: nil)
    redirect_to @club, notice: "Stripe account disconnected."
  end

  private

  def set_club
    # :state comes from Stripe callbacks
    @club = Club.friendly.find(params[:club_id] || params[:state])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless @club.is_owner?(current_user)
  end
end
