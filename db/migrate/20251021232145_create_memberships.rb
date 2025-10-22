class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :club, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :memberships, [ :user_id, :club_id ], unique: true
    add_index :memberships, :status
    add_index :memberships, :role
  end
end
