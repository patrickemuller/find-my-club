require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:endpoint_secret) { "whsec_test_secret" }
  let(:payload) { webhook_payload.to_json }
  let(:timestamp) { Time.current.to_i }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("STRIPE_WEBHOOK_SECRET", nil).and_return(endpoint_secret)
  end

  describe "POST /webhooks/stripe" do
    context "with valid signature" do
      before do
        # Mock successful signature verification
        allow(Stripe::Webhook).to receive(:construct_event).and_return(
          Stripe::Event.construct_from(webhook_payload)
        )
      end

      context "when receiving customer.subscription.updated event" do
        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "customer.subscription.updated",
            data: {
              object: {
                id: "sub_123456789",
                customer: "cus_123456789",
                status: "active",
                current_period_start: 1.day.ago.to_i,
                current_period_end: 1.month.from_now.to_i,
                cancel_at_period_end: false
              }
            }
          }
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs subscription update information" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("===== STRIPE WEBHOOK: Subscription Updated =====")
          expect(Rails.logger).to have_received(:info).with("Subscription ID: sub_123456789")
          expect(Rails.logger).to have_received(:info).with("Customer ID: cus_123456789")
          expect(Rails.logger).to have_received(:info).with("Status: active")
          expect(Rails.logger).to have_received(:info).with("Cancel At Period End: false")
          expect(Rails.logger).to have_received(:info).with("===============================================")
        end
      end

      context "when receiving customer.subscription.deleted event" do
        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "customer.subscription.deleted",
            data: {
              object: {
                id: "sub_123456789",
                customer: "cus_123456789",
                status: "canceled",
                canceled_at: Time.current.to_i
              }
            }
          }
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs subscription deletion information" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("===== STRIPE WEBHOOK: Subscription Deleted =====")
          expect(Rails.logger).to have_received(:info).with("Subscription ID: sub_123456789")
          expect(Rails.logger).to have_received(:info).with("Customer ID: cus_123456789")
          expect(Rails.logger).to have_received(:info).with("Status: canceled")
          expect(Rails.logger).to have_received(:info).with("===============================================")
        end
      end

      context "when receiving invoice.paid event" do
        let(:user) { create(:user) }
        let(:club) { create(:club, name: "Test Running Club") }
        let(:membership) { create(:membership, user: user, club: club, status: :active, stripe_subscription_id: "sub_123456789") }

        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "invoice.paid",
            data: {
              object: {
                id: "in_123456789",
                customer: "cus_123456789",
                subscription: "sub_123456789",
                amount_paid: 2000,
                currency: "usd",
                period_start: 1.day.ago.to_i,
                period_end: 1.month.from_now.to_i,
                number: "INV-2024-001",
                invoice_pdf: "https://invoice.stripe.com/i/acct_123/test_pdf"
              }
            }
          }
        end

        before do
          membership # Create membership before webhook
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs invoice paid information" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("===== STRIPE WEBHOOK: Invoice Paid =====")
          expect(Rails.logger).to have_received(:info).with("Invoice ID: in_123456789")
          expect(Rails.logger).to have_received(:info).with("Customer ID: cus_123456789")
          expect(Rails.logger).to have_received(:info).with("Subscription ID: sub_123456789")
          expect(Rails.logger).to have_received(:info).with("Amount Paid: 2000 USD")
          expect(Rails.logger).to have_received(:info).with("Invoice Number: INV-2024-001")
          expect(Rails.logger).to have_received(:info).with("Invoice PDF: https://invoice.stripe.com/i/acct_123/test_pdf")
          expect(Rails.logger).to have_received(:info).with("===============================================")
        end

        it "creates an Invoice record" do
          expect {
            post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          }.to change(Invoice, :count).by(1)

          invoice = Invoice.last
          expect(invoice.user).to eq(user)
          expect(invoice.stripe_invoice_id).to eq("in_123456789")
          expect(invoice.stripe_subscription_id).to eq("sub_123456789")
          expect(invoice.club_name).to eq("Test Running Club")
          expect(invoice.amount_cents).to eq(2000)
          expect(invoice.currency).to eq("usd")
          expect(invoice.status).to eq("paid")
          expect(invoice.invoice_number).to eq("INV-2024-001")
          expect(invoice.invoice_pdf_url).to eq("https://invoice.stripe.com/i/acct_123/test_pdf")
          expect(invoice.paid_at).to be_present
        end

        it "does not create duplicate Invoice records on retry" do
          # First webhook
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect {
            # Retry same webhook
            post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          }.not_to change(Invoice, :count)
        end

        context "when membership is not found" do
          let(:webhook_payload) do
            {
              id: "evt_test_webhook",
              type: "invoice.paid",
              data: {
                object: {
                  id: "in_999999999",
                  customer: "cus_999999999",
                  subscription: "sub_nonexistent",
                  amount_paid: 2000,
                  currency: "usd",
                  period_start: 1.day.ago.to_i,
                  period_end: 1.month.from_now.to_i,
                  number: "INV-2024-999",
                  invoice_pdf: "https://invoice.stripe.com/i/acct_123/test_pdf"
                }
              }
            }
          end

          it "does not create an Invoice record" do
            expect {
              post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
            }.not_to change(Invoice, :count)
          end

          it "still returns 200 status" do
            post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "when receiving invoice.payment_failed event" do
        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "invoice.payment_failed",
            data: {
              object: {
                id: "in_123456789",
                customer: "cus_123456789",
                subscription: "sub_123456789",
                amount_due: 2000,
                currency: "usd",
                attempt_count: 2
              }
            }
          }
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs payment failure information" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("===== STRIPE WEBHOOK: Invoice Payment Failed =====")
          expect(Rails.logger).to have_received(:info).with("Invoice ID: in_123456789")
          expect(Rails.logger).to have_received(:info).with("Customer ID: cus_123456789")
          expect(Rails.logger).to have_received(:info).with("Subscription ID: sub_123456789")
          expect(Rails.logger).to have_received(:info).with("Amount Due: 2000 USD")
          expect(Rails.logger).to have_received(:info).with("Attempt Count: 2")
          expect(Rails.logger).to have_received(:info).with("===============================================")
        end
      end

      context "when receiving invoice.updated event" do
        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "invoice.updated",
            data: {
              object: {
                id: "in_123456789",
                customer: "cus_123456789",
                subscription: "sub_123456789",
                status: "open",
                amount_due: 2000,
                currency: "usd"
              }
            }
          }
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs invoice update information" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("===== STRIPE WEBHOOK: Invoice Updated =====")
          expect(Rails.logger).to have_received(:info).with("Invoice ID: in_123456789")
          expect(Rails.logger).to have_received(:info).with("Customer ID: cus_123456789")
          expect(Rails.logger).to have_received(:info).with("Subscription ID: sub_123456789")
          expect(Rails.logger).to have_received(:info).with("Status: open")
          expect(Rails.logger).to have_received(:info).with("Amount Due: 2000 USD")
          expect(Rails.logger).to have_received(:info).with("===============================================")
        end
      end

      context "when receiving unhandled event type" do
        let(:webhook_payload) do
          {
            id: "evt_test_webhook",
            type: "customer.created",
            data: {
              object: {
                id: "cus_123456789",
                email: "test@example.com"
              }
            }
          }
        end

        it "returns 200 status" do
          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
          expect(response).to have_http_status(:ok)
        end

        it "logs unhandled event type" do
          allow(Rails.logger).to receive(:info)

          post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

          expect(Rails.logger).to have_received(:info).with("Unhandled Stripe webhook event type: customer.created")
        end
      end
    end

    context "with invalid signature" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new("Invalid signature", "sig_header")
        )
      end

      let(:webhook_payload) do
        {
          id: "evt_test_webhook",
          type: "customer.subscription.updated",
          data: { object: { id: "sub_123" } }
        }
      end

      it "returns 400 status" do
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "invalid_signature" }
        expect(response).to have_http_status(:bad_request)
      end

      it "logs signature verification error" do
        expect(Rails.logger).to receive(:error).with(/Stripe webhook error: Invalid signature/)
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "invalid_signature" }
      end
    end

    context "with invalid JSON payload" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          JSON::ParserError.new("unexpected token")
        )
      end

      let(:payload) { "invalid json {{{" }

      it "returns 400 status" do
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
        expect(response).to have_http_status(:bad_request)
      end

      it "logs JSON parse error" do
        expect(Rails.logger).to receive(:error).with(/Stripe webhook error: Invalid payload/)
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
      end
    end

    context "with missing Stripe signature header" do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new("No signature header", nil)
        )
      end

      let(:webhook_payload) do
        {
          id: "evt_test_webhook",
          type: "customer.subscription.updated",
          data: { object: { id: "sub_123" } }
        }
      end

      it "returns 400 status" do
        post "/webhooks/stripe", params: payload
        expect(response).to have_http_status(:bad_request)
      end

      it "logs signature verification error" do
        expect(Rails.logger).to receive(:error).with(/Stripe webhook error: Invalid signature/)
        post "/webhooks/stripe", params: payload
      end
    end

    context "with missing webhook secret in environment" do
      before do
        allow(ENV).to receive(:fetch).with("STRIPE_WEBHOOK_SECRET", nil).and_return(nil)
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new("Secret is blank", "sig_header")
        )
      end

      let(:webhook_payload) do
        {
          id: "evt_test_webhook",
          type: "customer.subscription.updated",
          data: { object: { id: "sub_123" } }
        }
      end

      it "returns 400 status" do
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
        expect(response).to have_http_status(:bad_request)
      end

      it "logs signature verification error" do
        expect(Rails.logger).to receive(:error).with(/Stripe webhook error: Invalid signature/)
        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }
      end
    end

    context "with minimal event data" do
      before do
        # Successfully verify signature but return event with minimal data
        allow(Stripe::Webhook).to receive(:construct_event).and_return(
          Stripe::Event.construct_from(webhook_payload)
        )
      end

      let(:webhook_payload) do
        # Missing optional fields
        {
          id: "evt_test_webhook",
          type: "customer.subscription.updated",
          data: {
            object: {
              id: "sub_123",
              customer: "cus_123",
              status: "active",
              current_period_start: Time.current.to_i,
              current_period_end: 1.month.from_now.to_i,
              cancel_at_period_end: false
            }
          }
        }
      end

      it "returns 200 status and handles missing optional fields" do
        allow(Rails.logger).to receive(:info)

        post "/webhooks/stripe", params: payload, headers: { "Stripe-Signature" => "valid_signature" }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
