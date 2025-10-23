class RemoveDescriptionAndRulesFromClubs < ActiveRecord::Migration[8.0]
  def change
    remove_column :clubs, :description, :text
    remove_column :clubs, :rules, :text
  end
end
