class AddSubscriptionFieldsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :stripe_subscription_id, :string
    add_column :memberships, :subscription_end_date, :datetime
  end
end
