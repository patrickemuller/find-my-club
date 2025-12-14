class Clubs::SubscriptionPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_club
  before_action :authorize_owner!

  def new
    @plan = @club.subscription_plans.build
  end

  def edit
    @plan = @club.subscription_plans.find(params[:id])
  end

  def create
    @plan = @club.subscription_plans.build(plan_params)

    # Convert price from dollars to cents
    if params[:subscription_plan][:price_cents].present?
      @plan.price_cents = (params[:subscription_plan][:price_cents].to_f * 100).to_i
    end

    begin

      price = Stripe::Price.create(
        {
          currency: "cad",
          unit_amount: @plan.price_cents,
          recurring: {
            interval: @plan.plan_type
          },
          product_data: {
            name: @plan.name
          }
        },
        {
          stripe_account: @club.stripe_account_id
        }
      )

      # TODO: rename this column back to price
      #       Stripe::Checkout::Session use the Price API instead of products
      @plan.stripe_product_id = price.id

      if @plan.save
        redirect_to club_payments_path(@club), notice: "Subscription plan created successfully!"
      else
        # Don't display anything related to Stripe API
        # It's the kind of thing that the user should NEVER see
        @plan.errors.errors.reject { |error| error.attribute.to_s.include?("stripe") } if Rails.env.production?
        render :new, status: :unprocessable_entity
      end
    rescue => e
      @plan.errors.add(:base, "Stripe error: #{e.message}") unless Rails.env.production?
      @plan.errors.add(:base, "Information is either missing or incorrect. Check information and try again.")
      @plan.errors.errors.reject { |error| error.attribute.to_s.include?("stripe") } if Rails.env.production?

      render :new, status: :unprocessable_entity
    end
  end

  def update
    @plan = @club.subscription_plans.find(params[:id])

    if @plan.update(plan_update_params)
      redirect_to club_payments_path(@club), notice: "Subscription plan updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_club
    @club = Club.friendly.find(params[:club_id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless @club.is_owner?(current_user)
  end

  def plan_params
    params.require(:subscription_plan).permit(:name, :plan_type, :price_cents, :description)
  end

  def plan_update_params
    params.require(:subscription_plan).permit(:name, :description, :active)
  end
end
