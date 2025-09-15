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

  description = "A welcoming #{category.downcase} club for #{level.downcase} athletes. We meet weekly for training and events around the city."
  rules       = "Be respectful, arrive on time, and support your teammates. Safety first on all outings."

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
