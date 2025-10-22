# Find My Club

A Rails application for discovering and managing sports clubs. Users can create clubs, browse public clubs by category and skill level, and manage their own club listings.

## Features

- User authentication with Devise
- Create and manage sports clubs
- Browse public clubs with search and filtering
- Club categorization by sport type and skill level
- Public/private club visibility settings
- SEO-friendly URLs with FriendlyId
- Responsive design with Tailwind CSS
- Hotwire (Turbo & Stimulus) for interactive features

## Requirements

- Ruby 3.4.3
- PostgreSQL 9.3 or higher
- Node.js (for JavaScript dependencies)

## System Dependencies

### macOS

```bash
# Install PostgreSQL
brew install postgresql
brew services start postgresql

# Install Ruby (using rbenv)
brew install rbenv ruby-build
rbenv install 3.4.3
rbenv global 3.4.3

# Install Node.js (for asset pipeline)
brew install node
```

### Linux (Ubuntu/Debian)

```bash
# Install PostgreSQL
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib libpq-dev

# Install Ruby dependencies
sudo apt-get install rbenv ruby-build

# Install Ruby
rbenv install 3.4.3
rbenv global 3.4.3

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Installation

1. Clone the repository:

```bash
git clone https://github.com/patrickemuller/find-my-club
cd find_my_club
```

2. Install Ruby dependencies:

```bash
bundle install
```

This will install all required gems including:
- Rails 8.0 (from stable branch)
- PostgreSQL adapter (pg gem)
- Devise for authentication
- FriendlyId for SEO-friendly URLs
- Kaminari for pagination
- Tailwind CSS for styling
- And all other dependencies listed in the Gemfile

3. Install JavaScript dependencies:

```bash
npm install
```

4. Set up the database:

```bash
# Create the database
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed the database with sample data
rails db:seed
```

## Configuration

### Database Configuration

The application uses PostgreSQL by default. Database configuration is in `config/database.yml`:

- Development database: `find_my_club_development`
- Test database: `find_my_club_test`
- Production: Uses `DATABASE_URL` environment variable

### Environment Variables

For production deployment, set the following environment variables:

```bash
RAILS_MASTER_KEY=<your-master-key>
```

The `RAILS_MASTER_KEY` can be found in `config/master.key` (do not commit this file).

## Running the Application

### Development Server

Start the Rails server:

```bash
rails server
```

Or use the shorter alias:

```bash
rails s
```

The application will be available at `http://localhost:3000`

### Asset Compilation

For Tailwind CSS to work properly in development, you may need to run:

```bash
rails tailwindcss:watch
```

Or use the Rails development task that runs both server and asset compilation:

```bash
bin/dev
```

## Running Tests

The project uses Rails' built-in testing framework (Minitest) with the following test types:

### Run All Tests

```bash
rails test
```

### Run Specific Test Types

```bash
# Run only model tests
rails test:models

# Run only controller tests
rails test:controllers

# Run system tests (integration tests with browser simulation)
rails test:system
```

### Run a Specific Test File

```bash
rails test test/models/club_test.rb
```

### Run a Specific Test

```bash
rails test test/models/club_test.rb:10
```

(Replace `10` with the line number of the test)

### System Testing

System tests use Selenium WebDriver with headless Chrome. Make sure you have Chrome or Chromium installed:

```bash
# macOS
brew install chromedriver

# Linux
sudo apt-get install chromium-chromedriver
```

Then run system tests:

```bash
rails test:system
```

## Test Helpers

The project includes:
- **FactoryBot**: For creating test data fixtures
- **Faker**: For generating realistic test data
- **Capybara**: For integration testing
- **Selenium WebDriver**: For browser-based system tests

## Code Quality Tools

### Linting

Run RuboCop for code style checks:

```bash
bundle exec rubocop
```

Auto-fix issues:

```bash
bundle exec rubocop -PA
```

### Security Scanning

Run Brakeman for security vulnerability checks:

```bash
bundle exec brakeman
```

## Project Structure

```
app/
├── controllers/    # Request handlers
├── models/         # Database models (Club, User)
├── views/          # HTML templates
├── helpers/        # View helpers
├── javascript/     # Stimulus controllers
└── assets/         # Images, stylesheets

test/
├── controllers/    # Controller tests
├── models/         # Model tests
├── system/         # End-to-end browser tests
└── fixtures/       # Test data

config/
├── database.yml    # Database configuration
├── routes.rb       # URL routing
└── credentials/    # Encrypted credentials
```

## Database Schema

Key models:

- **User**: Authenticated users (managed by Devise)
  - Email, password authentication
  - Has many clubs (as owner)

- **Club**: Sports club listings
  - Name, description, rules
  - Category (team sports, racket sports, etc.)
  - Skill level (beginner, intermediate, advanced, expert)
  - Public/private visibility
  - Active/disabled status
  - SEO-friendly slug (via FriendlyId)
  - Belongs to owner (User)

## Development Tools

- **Letter Opener**: Preview emails in the browser (development mode)
- **Web Console**: Interactive debugging console in error pages
- **Annotate**: Auto-annotate models with schema information
