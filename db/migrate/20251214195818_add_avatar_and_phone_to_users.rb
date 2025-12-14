class AddAvatarAndPhoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :country_code, :string
  end
end
