require "stripe"

Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
Stripe.client_id = ENV["STRIPE_CONNECT_CLIENT_ID"]
Stripe.api_version = "2024-11-20.acacia" # Use latest stable version
