require "stripe"

Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
Stripe.api_version = "2024-11-20.acacia" # Use latest stable version
