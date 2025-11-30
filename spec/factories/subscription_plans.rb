# == Schema Information
#
# Table name: subscription_plans
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  currency          :string           default("cad"), not null
#  description       :text
#  name              :string
#  plan_type         :string           not null
#  price_cents       :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  club_id           :bigint           not null
#  stripe_product_id :string           not null
#
# Indexes
#
#  index_subscription_plans_on_club_id            (club_id)
#  index_subscription_plans_on_stripe_product_id  (stripe_product_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#
FactoryBot.define do
  factory :subscription_plan do
    club { nil }
    stripe_product_id { "MyString" }
    plan_type { "MyString" }
    price_cents { 1 }
    currency { "MyString" }
    description { "MyText" }
    active { false }
  end
end
