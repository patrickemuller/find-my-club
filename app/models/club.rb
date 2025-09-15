class Club < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :owner, class_name: "User"

  validates :name, :description, :rules, :category, :level, presence: true
  validates :public, inclusion: { in: [ true, false ] }
end
