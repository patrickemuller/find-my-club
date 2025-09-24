# frozen_string_literal: true

# FactoryBot factories for Club model
# Usage examples:
#   create(:club)                        # creates club with an owner
#   build(:club, owner: build(:user))    # explicit owner
#   create(:club, public: true)

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
