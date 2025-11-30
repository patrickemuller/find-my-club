class RemoveUniquenessFromSubscriptionPlans < ActiveRecord::Migration[8.1]
  def change
    remove_index :subscription_plans, [ :club_id, :plan_type ]
  end
end
