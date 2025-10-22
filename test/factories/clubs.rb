# frozen_string_literal: true

# FactoryBot factories for Club model
# Usage examples:
#   create(:club)                        # creates club with an owner
#   build(:club, owner: build(:user))    # explicit owner
#   create(:club, public: true)

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
FactoryBot.define do
  factory :club do
    association :owner, factory: :user

    sequence(:name) { |n| "Downtown Runners #{n}" }
    description { "A welcoming club for athletes. We meet weekly for training and events around the city." }
    rules { "Be respectful. Arrive on time. Safety first on all outings." }

    # Keep category/level simple strings for now (app stores level as comma-separated string in forms)
    category { "Running, Ball Sports" }
    level    { "Beginner, Intermediate" }

    public { false }
    active { true }
  end
end
