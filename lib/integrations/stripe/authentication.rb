module Integrations
  module Stripe
    class Authentication
      class << self
        include Rails.application.routes.url_helpers

        def connect_oauth_uri(club)
          current_host = ENV.fetch("APP_HOST", "http://localhost:3000")
          redirect_uri = callbacks_stripe_url(host: current_host)
          club_id = club.id

          ::Stripe::OAuth.authorize_url(
            state: club_id,
            scope: "read_write",
            redirect_uri: redirect_uri
          )
        end

        # @param params [Params]
        # @param type [string] One of the two: "authorization_code" or "refresh_token"
        def get_token(params, type: "authorization_code")
          ::Stripe::OAuth.token(
            {
              grant_type: type,
              code: (type == "authorization_code" ? params[:code] : params[:refresh_token])
            }
          )
        end

        def deauthorize(club)
          platform_client_id = ENV.fetch("STRIPE_CONNECT_CLIENT_ID")

          ::Stripe::OAuth.deauthorize(
            {
              client_id: platform_client_id,
              stripe_user_id: club.stripe_account_id
            }
          )
        end
      end
    end
  end
end
