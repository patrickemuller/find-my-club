# == Schema Information
#
# Table name: clubs
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE)
#  category   :string           not null
#  level      :string           not null
#  name       :string           not null
#  public     :boolean          default(FALSE)
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint           not null
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

  LEVELS_FOR_SELECT = {
    "beginner" => "Beginner",
    "intermediate" => "Intermediate",
    "advanced" => "Advanced",
    "expert" => "Expert"
  }

  CATEGORIES_FOR_SELECT = {
    "team_ball_sports" => "Team Ball Sports",
    "racket_sports" => "Racket Sports",
    "combat_sports" => "Combat Sports",
    "aquatic_sports" => "Aquatic Sports",
    "athletics" => "Athletics",
    "winter_sports" => "Winter Sports",
    "cycling_sports" => "Cycling Sports",
    "other" => "Other"
  }

  friendly_id :name, use: :slugged

  belongs_to :owner, class_name: "User"

  # Rich text content
  has_rich_text :description
  has_rich_text :rules

  # Memberships
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user

  # Events
  has_many :events, dependent: :destroy

  validates :name, :category, :level, presence: true
  validates :description, :rules, presence: true
  validates :public, inclusion: { in: [ true, false ] }

  # Scopes
  scope :publicly_visible, -> { where(public: true) }

  scope :search, ->(search) do
    search.present? ? where("LOWER(name) LIKE :search", search: "%#{search.to_s.downcase}%") : all
  end

  scope :with_category, ->(categories) { categories.present? ? where("category IN (:categories)", categories: categories) : all }

  scope :with_level, ->(level) { level.present? ? where(level: level) : all }

  def should_generate_new_friendly_id?
    name_changed?
  end

  def private?
    !public?
  end

  def is_owner?(user)
    owner == user
  end

  def disabled?
    !active
  end

  def formatted_category
    categories = category.split(", ")
    categories.map { |c| CATEGORIES_FOR_SELECT[c] }.join(", ")
  end

  def formatted_level
    levels = level.split(", ")
    levels.map { |c| LEVELS_FOR_SELECT[c] }.join(", ")
  end

  # TODO: consider using counter_cache for this
  def members_count
    memberships.active.count
  end

  def has_member?(user)
    return false unless user
    memberships.active.exists?(user_id: user.id)
  end
end
