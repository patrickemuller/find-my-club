class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :club, null: false, foreign_key: true
      t.string :name, null: false
      t.string :location, null: false
      t.string :events, :location_name, :string, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :max_participants, null: false, default: 10
      t.boolean :has_waitlist, null: false, default: false
      t.string :slug

      t.timestamps
    end

    add_index :events, :slug, unique: true
  end
end
