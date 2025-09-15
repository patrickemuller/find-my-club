class CreateClubs < ActiveRecord::Migration[8.0]
  def change
    create_table :clubs do |t|
      t.belongs_to :owner, null: false, foreign_key: { to_table: :users }
      t.boolean :active, default: true
      t.string :name, null: false
      t.text :description, null: false
      t.text :rules, null: false
      t.string :category, null: false
      t.string :level, null: false
      t.boolean :public, default: false

      t.timestamps
    end
  end
end
