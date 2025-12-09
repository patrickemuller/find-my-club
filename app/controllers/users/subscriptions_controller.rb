class Users::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership, only: [ :destroy ]

  def index
    # Get all active memberships for paid clubs with their subscription plans
    @paid_memberships = current_user.memberships
                                    .active
                                    .joins(club: :subscription_plans)
                                    .where(clubs: { paid: true })
                                    .includes(club: :subscription_plans)
                                    .distinct

    @disabled_memberships = current_user.memberships
                                        .disabled
                                        .includes(club: :subscription_plans)
                                        .distinct

    # Get all invoices for the current user
    @invoices = current_user.invoices.order(paid_at: :desc)
  end

  def destroy
    unless @membership.stripe_subscription_id.present?
      redirect_to subscriptions_users_path, alert: "No active subscription found."
      return
    end

    begin
      # Cancel the subscription at period end (not immediately)
      Stripe::Subscription.update(
        @membership.stripe_subscription_id,
        { cancel_at_period_end: true },
        { stripe_account: @membership.club.stripe_account_id }
      )

      # Update membership to reflect cancellation
      @membership.update(stripe_subscription_cancel_at_period_end: true)

      redirect_to subscriptions_users_path,
                  notice: "Your subscription is now cancelled. Your last day as member of the club will be #{@membership.stripe_subscription_end_date.strftime('%B %d, %Y')}."
    rescue Stripe::StripeError => e
      redirect_to subscriptions_users_path, alert: "Failed to cancel subscription: #{e.message}"
    end
  end

  private

  def set_membership
    @membership = current_user.memberships.find(params[:id])
  end
end
