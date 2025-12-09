class Clubs::StripeAccountsController < ApplicationController
  before_action :authenticate_user!, except: [ :success ]
  before_action :set_club
  before_action :authorize_owner!, except: [ :checkout, :create_checkout_session, :success ]

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

  def checkout
    # Show available subscription plans
    @subscription_plans = @club.subscription_plans.active

    unless @club.can_accept_payments?
      redirect_to @club, alert: "This club is not set up to accept payments yet."
    end

    if current_user.can_join?(@club)
      # User can join, show checkout page
    else
      redirect_to @club, alert: "You cannot join this club."
    end
  end

  def create_checkout_session
    subscription_plan = @club.subscription_plans.find(params[:subscription_plan_id])

    unless @club.can_accept_payments?
      redirect_to @club, alert: "This club is not set up to accept payments yet."
    end

    unless current_user.can_join?(@club)
      redirect_to @club, alert: "You cannot join this club."
    end

    begin
      # Create Stripe Checkout Session
      session = Stripe::Checkout::Session.create(
        {
          mode: "subscription",
          customer_email: current_user.email,
          line_items: [
            {
              price: subscription_plan.stripe_product_id,
              quantity: 1
            }
          ],
          success_url: "#{club_checkout_success_url(@club)}?session_id={CHECKOUT_SESSION_ID}", # This is a magic String
          cancel_url: club_url(@club),
          metadata: {
            user_id: current_user.id,
            club_id: @club.id,
            subscription_plan_id: subscription_plan.id
          }
        },
        { stripe_account: @club.stripe_account_id }
      )

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to club_checkout_path(@club), alert: "An error occurred: #{e.message}"
    end
  end

  def success
    session_id = params[:session_id]

    unless session_id.present?
      redirect_to @club, alert: "Invalid checkout session."
    end

    begin
      # Retrieve the checkout session from Stripe
      checkout_session = Stripe::Checkout::Session.retrieve(
        session_id,
        { stripe_account: @club.stripe_account_id }
      )

      # Get user from session metadata
      user_id = checkout_session.metadata.user_id
      user = User.find(user_id)

      # Check if payment was successful
      if checkout_session.payment_status == "paid"
        # Get subscription details
        subscription = Stripe::Subscription.retrieve(
          { id: checkout_session.subscription },
          { stripe_account: @club.stripe_account_id }
        )

        # Calculate subscription end date
        subscription_end_date = Time.at(subscription.current_period_end)

        # Find or create membership (including disabled ones)
        membership = @club.memberships.find_or_initialize_by(user: user)
        membership.assign_attributes(
          status: "active",
          role: "member",
          stripe_subscription_id: subscription.id,
          stripe_subscription_end_date: subscription_end_date,
          stripe_subscription_cancel_at_period_end: false
        )
        membership.save!

        redirect_to @club, notice: "Payment successful! You have joined #{@club.name}."
      else
        redirect_to @club, alert: "Payment was not successful. Please try again."
      end
    rescue Stripe::StripeError => e
      redirect_to @club, alert: "An error occurred: #{e.message}"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to @club, alert: "Unable to create membership: #{e.message}"
    end
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
