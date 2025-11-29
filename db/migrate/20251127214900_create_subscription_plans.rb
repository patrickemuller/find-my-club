class CreateSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_plans do |t|
      t.references :club, null: false, foreign_key: true
      t.string :stripe_price_id, null: false
      t.string :plan_type, null: false
      t.integer :price_cents, null: false
      t.string :currency, default: "usd", null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :subscription_plans, :stripe_price_id, unique: true
    add_index :subscription_plans, [ :club_id, :plan_type ], unique: true
  end
end
