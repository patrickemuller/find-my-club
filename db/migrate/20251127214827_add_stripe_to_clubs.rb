class AddStripeToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :paid, :boolean, default: false, null: false
    add_column :clubs, :stripe_account_id, :string
    add_column :clubs, :stripe_account_status, :string

    add_index :clubs, :stripe_account_id
  end
end
