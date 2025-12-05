class Users::SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get all active memberships for paid clubs with their subscription plans
    @paid_memberships = current_user.memberships
                                    .active
                                    .joins(club: :subscription_plans)
                                    .where(clubs: { paid: true })
                                    .includes(club: :subscription_plans)
                                    .distinct
  end
end
