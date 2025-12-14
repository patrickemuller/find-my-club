class AddCancelAtPeriodEndToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :cancel_at_period_end, :boolean
  end
end
