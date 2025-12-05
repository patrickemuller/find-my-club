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
  end

  def handle_subscription_deleted(event)
    subscription = event.data.object
    Rails.logger.info "===== STRIPE WEBHOOK: Subscription Deleted ====="
    Rails.logger.info "Subscription ID: #{subscription.id}"
    Rails.logger.info "Customer ID: #{subscription.customer}"
    Rails.logger.info "Status: #{subscription.status}"
    Rails.logger.info "Canceled At: #{Time.at(subscription.canceled_at) if subscription.canceled_at}"
    Rails.logger.info "==============================================="
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
