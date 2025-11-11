class AddSocialMediaLinksToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :strava_url, :string
    add_column :users, :trailforks_url, :string
    add_column :users, :outside_url, :string
    add_column :users, :athlinks_url, :string
  end
end
