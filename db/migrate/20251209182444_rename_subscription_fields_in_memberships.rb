class RenameSubscriptionFieldsInMemberships < ActiveRecord::Migration[8.1]
  def change
    rename_column :memberships, :cancel_at_period_end, :stripe_subscription_cancel_at_period_end
    rename_column :memberships, :subscription_end_date, :stripe_subscription_end_date
  end
end
