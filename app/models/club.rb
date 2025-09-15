# == Schema Information
#
# Table name: clubs
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  category    :string           not null
#  description :text             not null
#  level       :string           not null
#  name        :string           not null
#  public      :boolean          default(FALSE)
#  rules       :text             not null
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#
# Indexes
#
#  index_clubs_on_owner_id  (owner_id)
#  index_clubs_on_slug      (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
class Club < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged

  belongs_to :owner, class_name: "User"

  validates :name, :description, :rules, :category, :level, presence: true
  validates :public, inclusion: { in: [ true, false ] }

  # Scopes
  scope :publicly_visible, -> { where(public: true) }

  scope :search, ->(search) do
    search.present? ? where("LOWER(name) LIKE :search", search: "%#{search.to_s.downcase}%") : all
  end

  scope :with_category, ->(category) { category.present? ? where(category: category) : all }

  scope :with_level, ->(level) { level.present? ? where(level: level) : all }
end
