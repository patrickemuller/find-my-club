class CreateClubInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :club_invitations do |t|
      t.references :club, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.string :status, default: "pending", null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :club_invitations, [ :club_id, :email ], unique: true, where: "status = 'pending'"
    add_index :club_invitations, :token, unique: true
    add_index :club_invitations, :email
    add_index :club_invitations, :status
  end
end
