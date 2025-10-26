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

# Get existing users or create new ones to reach 500 total
existing_users = User.where.not(email: 'developer@example.com').to_a
additional_users_needed = 500 - existing_users.count

if additional_users_needed > 0
  puts "Creating #{additional_users_needed} additional users..."
  new_users = FactoryBot.create_list(:user, additional_users_needed)
  users = existing_users + new_users
else
  puts "Using existing #{existing_users.count} users..."
  users = existing_users
end

puts "Seeding clubs..."

categories = Club::CATEGORIES_FOR_SELECT.keys
levels = Club::LEVELS_FOR_SELECT.keys

# Deterministic seed so the same clubs are generated each run
seed = 123
srand(seed)

name_parts_left = %w[North South East West Central Urban Rural Coastal Mountain Lakeside]
name_parts_right = %w[Striders Cyclists Swimmers Runners Paddlers Racers Sprinters Wanderers Climbers Rowers]
name_suffixes = %w[Club Team Crew Squad League Collective Association Group Network]

(1..1000).each do |i|
  name = [
           "#{name_parts_left.sample} #{name_parts_right.sample}",
           "#{%w[City County Metro Valley River Ridge Bay Prairie Forest Desert].sample} #{name_suffixes.sample}"
         ].sample + " #{i}"

  category = categories.sample
  level = levels.sample

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
  club.owner = owner
  club.category = category
  club.level = level
  club.description = description
  club.rules = rules
  club.public = [ true, false ].sample
  club.active = true
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

puts "\nSeeding events..."

# Create events for each club (10 events per club)
Club.find_each do |club|
  # Get active members for this club
  active_members = club.memberships.active.includes(:user).map(&:user)

  # Skip clubs with no active members
  next if active_members.empty?

  10.times do |i|
    # Randomize event timing: 50% upcoming, 50% past
    if i < 5
      # Upcoming events
      starts_at = rand(1..30).days.from_now + rand(0..23).hours
    else
      # Past events
      starts_at = rand(1..60).days.ago + rand(0..23).hours
    end

    ends_at = starts_at + rand(1..4).hours

    # Randomize event settings
    max_participants = [ 5, 10, 15, 20, 25, 30 ].sample
    has_waitlist = [ true, false ].sample

    # Generate event description
    event_description = <<~HTML
      <p><strong>Join us for an exciting event!</strong></p>
      <p>#{FFaker::Lorem.paragraph}</p>
      <p>#{FFaker::Lorem.paragraph}</p>
    HTML

    # Create the event (skip validation for past events)
    city = FFaker::Address.city
    street = FFaker::Address.street_name
    location_name = "#{city} #{street}"

    event = club.events.new(
      name: "#{FFaker::Company.catch_phrase} #{i + 1}",
      description: event_description,
      location: "https://maps.google.com/?q=#{city}+#{street}",
      location_name: location_name,
      starts_at: starts_at,
      ends_at: ends_at,
      max_participants: max_participants,
      has_waitlist: has_waitlist
    )

    # For past events, skip validation to allow creation
    if starts_at < Time.current
      event.save(validate: false)
    else
      event.save!
    end

    # Determine how many registrations to create (vary between 0 and max+5)
    registration_count = rand(0..[ max_participants + 5, active_members.count ].min)

    # Select random members for registration
    registered_members = active_members.sample(registration_count)

    registered_members.each_with_index do |member, index|
      # Determine status based on capacity
      if index < max_participants
        # First members up to max are confirmed
        status = 'confirmed'
      elsif has_waitlist
        # If event has waitlist, excess members go to waitlist
        status = 'waitlist'
      else
        # If no waitlist and event is full, skip this registration
        next
      end

      # Create event registration
      event.event_registrations.create!(
        user: member,
        status: status
      )
    rescue ActiveRecord::RecordInvalid => e
      # Skip if validation fails (e.g., duplicate registration)
      # Silently skip to avoid cluttering output
    end
  rescue ActiveRecord::RecordInvalid => e
    # Skip if event validation fails
    # Silently skip to avoid cluttering output
  end

  print "."
end

puts "\nDone."

# Print summary
puts "\nSummary:"
puts "Total Clubs: #{Club.count}"
puts "Total Users: #{User.count}"
puts "Total Memberships: #{Membership.count}"
puts "  Active: #{Membership.active.count}"
puts "  Pending: #{Membership.pending.count}"
puts "  Disabled: #{Membership.disabled.count}"
puts "Total Events: #{Event.count}"
puts "  Upcoming: #{Event.upcoming.count}"
puts "  Past: #{Event.past.count}"
puts "Total Event Registrations: #{EventRegistration.count}"
puts "  Confirmed: #{EventRegistration.confirmed.count}"
puts "  Waitlist: #{EventRegistration.waitlist.count}"
