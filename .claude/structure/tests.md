# Tests

This document provides a breakdown of all test files and testing infrastructure in the Find My Club application.

## Testing Framework

**Framework:** RSpec Rails
**Test Database:** PostgreSQL (find_my_club_test)

---

## Test Configuration

### RSpec Configuration Files

**spec_helper.rb**
- Core RSpec configuration
- Expectation/mock settings
- No Rails dependencies
- Shared context behavior

**rails_helper.rb**
- Rails-specific RSpec configuration
- Loads Rails test environment
- Auto-requires all support files from `spec/support/`
- Maintains test schema
- Infers spec types from file location
- Disables transactional fixtures (using DatabaseCleaner instead)

**.rspec**
- Command-line options
- Requires spec_helper
- Output format settings

---

## Test Support Files

**Directory:** `spec/support/`

### Capybara
**File:** `spec/support/capybara.rb`

**Configuration:**
- Browser driver setup (headless Chrome)
- Server settings
- Screenshot settings
- JavaScript testing enabled

### Factory Bot
**File:** `spec/support/factory_bot.rb`

**Configuration:**
- Factory Bot syntax methods
- Integrates FactoryBot with RSpec

### Devise
**File:** `spec/support/devise.rb`

**Configuration:**
- Devise test helpers
- Sign in/out helper methods
- Request spec helpers

### Database Cleaner
**File:** `spec/support/database_cleaner.rb`

**Configuration:**
- Database cleaning strategy
- Transaction/truncation settings
- Cleans database between tests

### WebMock
**File:** `spec/support/webmock.rb`

**Configuration:**
- HTTP request stubbing
- External API mocking
- Prevents real HTTP requests in tests

---

## Test Types

### Model Specs

**Directory:** `spec/models/`

**Files:**
- `user_spec.rb` - User model tests
- `club_spec.rb` - Club model tests
- `membership_spec.rb` - Membership model tests
- `event_spec.rb` - Event model tests
- `event_registration_spec.rb` - EventRegistration model tests

**Coverage:**
- Validations
- Associations
- Scopes
- Instance methods
- Class methods
- Business logic

**Example patterns:**
```ruby
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
  end

  describe 'associations' do
    it { should have_many(:clubs) }
  end

  describe '#member_of?' do
    # Test instance method
  end
end
```

---

### Request Specs

**Directory:** `spec/requests/`

**Files:**
- `pages_spec.rb` - Pages controller requests
- `clubs_spec.rb` - Clubs controller requests
- `memberships_spec.rb` - Memberships controller requests
- `places_spec.rb` - Places autocomplete API
- `users/profiles_spec.rb` - User profiles requests

**Coverage:**
- HTTP requests (GET, POST, PUT, DELETE)
- Response status codes
- Response body/JSON
- Redirects
- Authentication/authorization
- API endpoints

**Example patterns:**
```ruby
RSpec.describe "Clubs", type: :request do
  describe "GET /clubs" do
    it "returns success" do
      get clubs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /clubs" do
    context "with valid parameters" do
      it "creates a new club" do
        expect {
          post clubs_path, params: { club: valid_attributes }
        }.to change(Club, :count).by(1)
      end
    end
  end
end
```

---

### System Specs

**Directory:** `spec/system/`

**Files:**
- `clubs_spec.rb` - Club management flows
- `memberships_spec.rb` - Membership flows
- `header_navigation_spec.rb` - Navigation testing
- `profile_carousel_spec.rb` - Profile carousel feature
- `registrations_spec.rb` - User registration and account edit flows

**Coverage:**
- End-to-end user flows
- JavaScript interactions
- Form submissions
- Page navigation
- Visual elements
- Turbo/Stimulus controllers

**Features:**
- Headless Chrome driver
- Screenshot on failure
- JavaScript enabled
- Full page rendering

**Example patterns:**
```ruby
RSpec.describe "Clubs", type: :system do
  it "allows user to create a club" do
    visit new_club_path

    fill_in "Name", with: "Test Club"
    select "Beginner", from: "Level"
    click_button "Create Club"

    expect(page).to have_content("Club created successfully")
    expect(page).to have_content("Test Club")
  end
end
```

---

### Mailer Specs

**Directory:** `spec/mailers/`

**Files:**
- `membership_mailer_spec.rb` - Email tests

**Coverage:**
- Email delivery
- Email content
- Recipients
- Subject lines
- Attachments

**Mailer Previews:**
**File:** `spec/mailers/previews/membership_mailer_preview.rb`
- Preview emails in browser at `/rails/mailers`

---

## Factories

**Directory:** `spec/factories/`

**FactoryBot Definitions:**

**users.rb**
- User factory
- Traits for different user states
- Admin users
- Confirmed/unconfirmed users

**clubs.rb**
- Club factory
- Public/private clubs
- Different categories and levels
- Associated with owner

**memberships.rb**
- Membership factory
- Different statuses (active, pending, disabled)
- Different roles
- Associated with user and club

**events.rb**
- Event factory
- Upcoming/past events
- With/without waitlist
- Different participant limits
- Associated with club

**event_registrations.rb**
- EventRegistration factory
- Different statuses (confirmed, waitlist)
- Associated with user and event

**Usage Example:**
```ruby
# Create a user
user = create(:user)

# Create with overrides
club = create(:club, name: "Custom Club", owner: user)

# Build without saving
event = build(:event, club: club)

# Create with traits
membership = create(:membership, :pending)
```

---

## Test Coverage

### Current Coverage Areas

**Models:**
- ✅ User validations and methods
- ✅ Club business logic
- ✅ Membership state management
- ✅ Event registration logic
- ✅ Associations and relationships

**Controllers/Requests:**
- ✅ Club CRUD operations
- ✅ Membership management
- ✅ Event operations
- ✅ User profiles
- ✅ Places API

**System/Integration:**
- ✅ Club creation and management
- ✅ Membership workflows
- ✅ Navigation
- ✅ Profile features

**Mailers:**
- ✅ Membership notifications

---

## Running Tests

### Full Test Suite
```bash
bundle exec rspec
```

### Specific Test Types
```bash
# Model tests only
bundle exec rspec spec/models

# Request tests only
bundle exec rspec spec/requests

# System tests only
bundle exec rspec spec/system

# Single file
bundle exec rspec spec/models/user_spec.rb

# Single example
bundle exec rspec spec/models/user_spec.rb:10
```

### With Coverage Report
```bash
COVERAGE=true bundle exec rspec
```

### Formatted Output
```bash
# Documentation format
bundle exec rspec -fd

# Fail fast (stop on first failure)
bundle exec rspec --fail-fast
```

---

## Testing Tools & Gems

### Core Testing
- **rspec-rails** - RSpec for Rails
- **rspec-expectations** - Matchers
- **rspec-mocks** - Test doubles

### Database
- **database_cleaner** - Clean database between tests
- **factory_bot_rails** - Test data factories

### Integration Testing
- **capybara** - System test framework
- **selenium-webdriver** - Browser automation
- **webdrivers** - Auto-install browser drivers

### Helpers
- **shoulda-matchers** - One-liner matchers for validations/associations
- **faker** - Generate fake data
- **webmock** - Stub HTTP requests

### Code Quality
- **simplecov** - Code coverage reports (when enabled)

---

## Test Data Strategy

### Factories over Fixtures
- Use FactoryBot factories
- No fixtures files
- Dynamic test data
- Explicit associations

### Data Cleanup
- DatabaseCleaner with transaction strategy
- Each test starts with clean database
- Isolation between tests

### Mocking External Services
- WebMock stubs HTTP requests
- No real API calls in tests
- Predictable test behavior

---

## Best Practices

### Model Tests
- Test validations
- Test associations
- Test scopes
- Test instance methods
- Test class methods
- Test callbacks

### Request Tests
- Test authentication/authorization
- Test status codes
- Test redirects
- Test response formats
- Test CRUD operations

### System Tests
- Test user workflows
- Test JavaScript interactions
- Test form submissions
- Test navigation
- Use page objects for complex flows

### General
- One assertion per test (when possible)
- Descriptive test names
- Use `let` and `let!` for setup
- Use `before` hooks sparingly
- Keep tests DRY but readable
- Test edge cases and errors

---

## Continuous Integration

**CI Configuration:**
- Tests run on git push
- Must pass before merge
- Coverage reports generated
- Database setup automated

**Environment:**
- PostgreSQL test database
- Headless Chrome for system tests
- All dependencies cached

---

## Test Helpers

### Custom Matchers
Can be added to `spec/support/custom_matchers.rb`

### Shared Examples
Can be added to `spec/support/shared_examples/`

### Helper Methods
Defined in support files or spec_helper/rails_helper

---

## Debugging Tests

### Pry
```ruby
require 'pry'
binding.pry # Add to test for debugging
```

### Screenshots (System Tests)
- Automatically saved on failure
- Located in `tmp/screenshots/`

### Database Inspection
```bash
# Access test database
rails db -e test
```

### Verbose Output
```bash
bundle exec rspec --format documentation
```

---

## Future Testing Considerations

**Areas for Expansion:**
- Controller specs (if needed)
- Background job tests
- Webhook tests
- Performance tests
- Security tests
- Email delivery integration
- File upload tests
- API endpoint tests
