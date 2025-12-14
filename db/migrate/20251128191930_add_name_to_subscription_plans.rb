class AddNameToSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :subscription_plans, :name, :string
  end
end
