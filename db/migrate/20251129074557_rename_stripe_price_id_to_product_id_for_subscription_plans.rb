class RenameStripePriceIdToProductIdForSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    rename_column :subscription_plans, :stripe_price_id, :stripe_product_id
  end
end
