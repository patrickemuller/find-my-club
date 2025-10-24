require 'ffaker'

# Seed users and clubs with deterministic, idempotent fake data inspired by ClubsController
# Run with: bin/rails db:seed

puts "Seeding users..."

# Create or find the developer user
User.find_or_create_by(email: 'developer@example.com') do |user|
  user.admin = true
  user.first_name = 'Developer'
  user.last_name = 'Localhost'
  user.password = 'password'
  user.password_confirmation = 'password'
  user.confirmed_at = Time.current
end

# We'll create 500 users total and reuse them across clubs
users = FactoryBot.create_list(:user, 500)

puts "Seeding clubs..."

categories = Club::CATEGORIES_FOR_SELECT.keys
levels     = Club::LEVELS_FOR_SELECT.keys

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
  rules = "<ol>\n" + rule_items.map { |s| "  <li>#{s}</li>" }.join("\n") + "\n</ol>\n"

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

puts "Seeding memberships..."

# Add members to each club (10-50 members per club with varied statuses)
Club.find_each do |club|
  # Determine how many members this club should have (10-50)
  member_count = rand(10..50)

  # Get potential members (exclude the club owner)
  available_users = users.reject { |u| u.id == club.owner_id }

  # Randomly select members for this club
  selected_members = available_users.sample(member_count)

  selected_members.each_with_index do |user, index|
    # Distribute statuses: ~70% active, ~20% pending, ~10% disabled
    status = if index < (member_count * 0.7).to_i
               'active'
    elsif index < (member_count * 0.9).to_i
               'pending'
    else
               'disabled'
    end

    # Create membership if it doesn't exist
    Membership.find_or_create_by(user: user, club: club) do |membership|
      membership.status = status
      membership.role = 'member'
    end
  rescue ActiveRecord::RecordInvalid => e
    # Skip if validation fails (e.g., owner trying to be a member)
    puts "Skipped membership: #{e.message}"
  end

  print "."
end

puts "\nDone."
