class MigrateClubContentToActionText < ActiveRecord::Migration[8.0]
  def up
    # Temporarily disable the has_rich_text associations by using raw SQL
    Club.find_each do |club|
      desc_content = club.read_attribute(:description)
      rules_content = club.read_attribute(:rules)

      # Create ActionText::RichText records manually
      ActionText::RichText.create!(
        record_type: 'Club',
        record_id: club.id,
        name: 'description',
        body: desc_content
      )

      ActionText::RichText.create!(
        record_type: 'Club',
        record_id: club.id,
        name: 'rules',
        body: rules_content
      )
    end
  end

  def down
    # Remove Action Text records for clubs
    ActionText::RichText.where(record_type: 'Club', name: [ 'description', 'rules' ]).destroy_all
  end
end
