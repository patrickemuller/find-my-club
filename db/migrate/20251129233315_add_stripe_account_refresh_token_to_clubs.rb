class AddStripeAccountRefreshTokenToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :stripe_account_refresh_token, :string
  end
end
