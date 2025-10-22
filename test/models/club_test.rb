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
require "test_helper"

class ClubTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
