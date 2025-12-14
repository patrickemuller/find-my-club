class RemoveEventsFieldFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :events
  end
end
