class Webhooks::StripeController < ApplicationController
  # Skip CSRF token verification for webhook requests
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )

      # Handle the event
      case event.type
      when "customer.subscription.updated"
        handle_subscription_updated(event)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event)
      when "invoice.paid"
        handle_invoice_paid(event)
      when "invoice.payment_failed"
        handle_invoice_payment_failed(event)
      when "invoice.updated"
        handle_invoice_updated(event)
      else
        Rails.logger.info "Unhandled Stripe webhook event type: #{event.type}"
      end

      head :ok
    rescue JSON::ParserError => e
      # Invalid payload
      Rails.logger.error "Stripe webhook error: Invalid payload - #{e.message}"
      head :bad_request
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      Rails.logger.error "Stripe webhook error: Invalid signature - #{e.message}"
      head :bad_request
    end
  end

  private

  def handle_subscription_updated(event)
    subscription = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Subscription Updated ====="
    Rails.logger.info "Subscription ID: #{subscription.id}"
    Rails.logger.info "Customer ID: #{subscription.customer}"
    Rails.logger.info "Status: #{subscription.status}"
    Rails.logger.info "Current Period Start: #{Time.at(subscription.current_period_start)}"
    Rails.logger.info "Current Period End: #{Time.at(subscription.current_period_end)}"
    Rails.logger.info "Cancel At Period End: #{subscription.cancel_at_period_end}"
    Rails.logger.info "==============================================="

    # Find the membership via subscription ID and update renewal date
    membership = Membership.find_by(stripe_subscription_id: subscription.id)
    if membership
      membership.update(
        stripe_subscription_end_date: Time.at(subscription.current_period_end),
        stripe_subscription_cancel_at_period_end: subscription.cancel_at_period_end
      )
      Rails.logger.info "Updated membership #{membership.id} with renewal date: #{Time.at(subscription.current_period_end)} and cancel_at_period_end: #{subscription.cancel_at_period_end}"
    end
  end

  def handle_subscription_deleted(event)
    subscription = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Subscription Deleted ====="
    Rails.logger.info "Subscription ID: #{subscription.id}"
    Rails.logger.info "Customer ID: #{subscription.customer}"
    Rails.logger.info "Status: #{subscription.status}"
    Rails.logger.info "Canceled At: #{Time.at(subscription.canceled_at) if subscription.canceled_at}"
    Rails.logger.info "==============================================="

    # Find the membership via subscription ID
    membership = Membership.find_by(stripe_subscription_id: subscription.id)
    if membership
      # Disable the membership and clear subscription data
      membership.update(
        status: "disabled",
        stripe_subscription_id: nil,
        stripe_subscription_end_date: nil,
        stripe_subscription_cancel_at_period_end: nil
      )
      Rails.logger.info "Disabled membership #{membership.id} and cleared subscription data"
    end
  end

  def handle_invoice_paid(event)
    invoice = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Invoice Paid ====="
    Rails.logger.info "Invoice ID: #{invoice.id}"
    Rails.logger.info "Customer ID: #{invoice.customer}"
    Rails.logger.info "Subscription ID: #{invoice.subscription}"
    Rails.logger.info "Amount Paid: #{invoice.amount_paid} #{invoice.currency.upcase}"
    Rails.logger.info "Period Start: #{Time.at(invoice.period_start) if invoice.period_start}"
    Rails.logger.info "Period End: #{Time.at(invoice.period_end) if invoice.period_end}"
    Rails.logger.info "Invoice Number: #{invoice.number}"
    Rails.logger.info "Invoice PDF: #{invoice.invoice_pdf}"
    Rails.logger.info "==============================================="

    # Find the membership via subscription ID
    membership = Membership.find_by(stripe_subscription_id: invoice.subscription)

    # Create invoice record
    inv = Invoice.find_or_initialize_by(stripe_invoice_id: invoice.id)
    inv.user = membership.user
    inv.stripe_subscription_id = invoice.subscription
    inv.club_name = membership.club.name
    inv.amount_cents = invoice.amount_paid
    inv.currency = invoice.currency
    inv.status = "paid"
    inv.invoice_number = invoice.number
    inv.invoice_pdf_url = invoice.invoice_pdf
    inv.period_start = Time.at(invoice.period_start) if invoice.period_start
    inv.period_end = Time.at(invoice.period_end) if invoice.period_end
    inv.paid_at = Time.current
    inv.save
  end

  def handle_invoice_payment_failed(event)
    invoice = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Invoice Payment Failed ====="
    Rails.logger.info "Invoice ID: #{invoice.id}"
    Rails.logger.info "Customer ID: #{invoice.customer}"
    Rails.logger.info "Subscription ID: #{invoice.subscription}"
    Rails.logger.info "Amount Due: #{invoice.amount_due} #{invoice.currency.upcase}"
    Rails.logger.info "Attempt Count: #{invoice.attempt_count}"
    Rails.logger.info "==============================================="
  end

  def handle_invoice_updated(event)
    invoice = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Invoice Updated ====="
    Rails.logger.info "Invoice ID: #{invoice.id}"
    Rails.logger.info "Customer ID: #{invoice.customer}"
    Rails.logger.info "Subscription ID: #{invoice.subscription}"
    Rails.logger.info "Status: #{invoice.status}"
    Rails.logger.info "Amount Due: #{invoice.amount_due} #{invoice.currency.upcase}"
    Rails.logger.info "==============================================="
  end
end
