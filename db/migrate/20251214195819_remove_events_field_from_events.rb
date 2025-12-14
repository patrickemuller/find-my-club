class RemoveEventsFieldFromEvents < ActiveRecord::Migration[8.1]
  def change
    if column_exists?(:events, :events)
      remove_column :events, :events
    end

    if column_exists?(:events, :string)
      remove_column :events, :string
    end
  end
end
