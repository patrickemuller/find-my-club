class Clubs::StripeAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_club
  before_action :authorize_owner!

  def new
    # Show connect Stripe page
  end

  def show
    # Show Stripe account status and management options
  end

  def create
    # Redirect to Stripe Connect OAuth
    redirect_to StripeService.create_account_link(@club), allow_other_host: true
  end

  def destroy
    @club.update(stripe_account_id: nil, stripe_account_status: nil)
    redirect_to @club, notice: "Stripe account disconnected."
  end

  private

  def set_club
    @club = Club.friendly.find(params[:club_id] || params[:state])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless @club.is_owner?(current_user)
  end
end
