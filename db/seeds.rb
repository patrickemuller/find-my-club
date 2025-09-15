require 'ffaker'

# Seed users and clubs with deterministic, idempotent fake data inspired by ClubsController
# Run with: bin/rails db:seed

puts "Seeding users..."

FactoryBot.create(:user, admin: true, email: 'admin@example.com', password: 'password')

users = FactoryBot.create_list(:user, 10)

puts "Seeding clubs..."

categories = %w[Running Cycling Swimming Football Basketball Tennis Volleyball Hiking Climbing Rowing]
levels     = [ "Beginner", "Intermediate", "Advanced", "Expert" ]

# Deterministic seed so the same clubs are generated each run
seed = 123
srand(seed)

name_parts_left  = %w[North South East West Central Urban Rural Coastal Mountain Lakeside]
name_parts_right = %w[Striders Cyclists Swimmers Runners Paddlers Racers Sprinters Wanderers Climbers Rowers]
name_suffixes    = %w[Club Team Crew Squad League Collective Association Group Network]

(1..1000).each do |i|
  name = [
    "#{name_parts_left.sample} #{name_parts_right.sample}",
    "#{%w[City County Metro Valley River Ridge Bay Prairie Forest Desert].sample} #{name_suffixes.sample}"
  ].sample + " #{i}"

  category = categories.sample
  level    = levels.sample

  # Generate HTML description using FFaker
  description = <<~HTML
    <p>
      Welcome to the <strong>#{category}</strong> club for <em>#{level.downcase}</em> athletes.
    </p>
    <p>#{FFaker::Lorem.paragraph}</p>
    <p>#{FFaker::Lorem.paragraph}</p>
    <p>#{FFaker::Lorem.paragraph}</p>
    <p>#{FFaker::Lorem.paragraph}</p>
    <p>#{FFaker::Lorem.paragraph}</p>
  HTML

  # Generate HTML rules list using FFaker
  rule_items = Array.new(rand(5..8)) { FFaker::Lorem.sentence(rand(8..16)) }
  rules = "<ul>\n" + rule_items.map { |s| "  <li>#{s}</li>" }.join("\n") + "\n</ul>\n"

  owner = users[i % users.length]

  club = Club.find_or_initialize_by(name: name)
  club.owner       = owner
  club.category    = category
  club.level       = level
  club.description = description
  club.rules       = rules
  club.public      = [ true, false ].sample
  club.active      = true
  club.save!
end

puts "Done."
