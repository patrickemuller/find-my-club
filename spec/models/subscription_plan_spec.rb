# == Schema Information
#
# Table name: subscription_plans
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  currency        :string           default("cad"), not null
#  description     :text
#  name            :string
#  plan_type       :string           not null
#  price_cents     :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  club_id         :bigint           not null
#  stripe_price_id :string           not null
#
# Indexes
#
#  index_subscription_plans_on_club_id                (club_id)
#  index_subscription_plans_on_club_id_and_plan_type  (club_id,plan_type) UNIQUE
#  index_subscription_plans_on_stripe_price_id        (stripe_price_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#
require 'rails_helper'

RSpec.describe SubscriptionPlan, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
