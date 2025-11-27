# Lib & Helpers

This document provides a breakdown of library code, helpers, and custom utilities in the Find My Club application.

## Lib Directory

**Directory:** `lib/`

**Purpose:** Custom libraries, modules, and utilities

**Configuration:** Auto-loaded by Rails (excludes `tasks` and `assets` subdirectories)

---

## Rake Tasks

**Directory:** `lib/tasks/`

### AnnotateRb Task
**File:** `lib/tasks/annotate_rb.rake`

**Purpose:** Automatically annotate model files with schema information

**Features:**
- Runs in development environment only
- Triggered on database migrations
- Adds schema comments to model files
- Can be skipped with `ANNOTATERB_SKIP_ON_DB_TASKS` env var

**Usage:**
```bash
# Annotate models
rails annotate_rb:annotate

# Skip annotation on db tasks
ANNOTATERB_SKIP_ON_DB_TASKS=1 rails db:migrate
```

**Output Example:**
```ruby
# == Schema Information
#
# Table name: users
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  ...
```

---

## Helpers

**Directory:** `app/helpers/`

### Application Helper

**File:** `app/helpers/application_helper.rb`

**Purpose:** Global helper methods available across all views

**Methods:**

#### `inline_svg(filename, options = {})`
Renders SVG icons inline in HTML

**Parameters:**
- `filename` (string) - SVG filename without extension
- `options` (hash) - Optional attributes
  - `:class` - CSS classes to apply

**Returns:** HTML-safe SVG string

**Example:**
```erb
<%= inline_svg("google_calendar", class: "w-5 h-5") %>
```

**Location:** Reads from `app/assets/icons/*.svg`

**Usage:**
- Social media icons
- UI icons
- Custom graphics

---

### Events Helper

**File:** `app/helpers/events_helper.rb`

**Purpose:** Helper methods for event-related views

**Methods:**

#### `google_calendar_url(event)`
Generates Google Calendar "Add Event" URL

**Parameters:**
- `event` (Event) - Event object

**Returns:** Google Calendar URL string

**Query Parameters:**
- `action`: TEMPLATE
- `text`: Event name
- `dates`: Start/end in format YYYYMMDDTHHMMSS
- `details`: Event description (HTML stripped)
- `location`: Location name or URL

**Example:**
```erb
<%= link_to "Add to Google Calendar", google_calendar_url(@event) %>
```

---

#### `google_maps_embed_url(location_url)`
Converts Google Maps URL to embeddable iframe URL

**Parameters:**
- `location_url` (string) - Google Maps URL or location string

**Returns:** Embeddable Google Maps URL

**Supported Formats:**
- `https://maps.google.com/?q=Location+Name`
- `https://www.google.com/maps/search/Location+Name`
- `https://maps.google.com/maps?q=40.7128,-74.0060`
- Plain text location names (as fallback)

**Output Format:**
- `https://maps.google.com/maps?q=QUERY&output=embed`

**Error Handling:**
- Invalid URIs treated as search terms
- Graceful fallback for malformed URLs

**Example:**
```erb
<iframe src="<%= google_maps_embed_url(@event.location) %>"></iframe>
```

---

### Clubs Helper

**File:** `app/helpers/clubs_helper.rb`

**Purpose:** Helper methods for club-related views

**Current State:** Empty (generated scaffold)

**Potential Uses:**
- Club status badges
- Category/level formatting
- Member count display
- Visibility indicators

---

### Pages Helper

**File:** `app/helpers/pages_helper.rb`

**Purpose:** Helper methods for static pages

**Current State:** Empty (generated scaffold)

**Potential Uses:**
- Home page utilities
- Marketing content helpers

---

## Helper Patterns & Best Practices

### When to Use Helpers

**Good Use Cases:**
- View-specific formatting logic
- URL generation
- Complex conditionals for display
- Reusable view components
- External API integrations (calendars, maps)

**Avoid:**
- Business logic (belongs in models)
- Database queries (belongs in controllers/models)
- Complex algorithms (belongs in service objects)

---

### Helper Organization

**Application Helper:**
- Global utilities
- Common UI components
- Cross-cutting concerns

**Model Helpers:**
- Model-specific formatting
- Display logic for that model
- Associated view utilities

**Module Inclusion:**
Rails automatically includes:
- `ApplicationHelper` in all views
- Corresponding helper in specific views (e.g., `EventsHelper` in events views)

---

## Custom Libraries

**Directory:** `lib/` (excluding tasks)

**Current State:** No custom libraries currently

**Potential Additions:**

### Service Objects
**Location:** `lib/services/` or `app/services/`

**Purpose:** Complex business logic

**Examples:**
- Event registration service
- Membership approval workflow
- Email notification service

### Validators
**Location:** `lib/validators/` or `app/validators/`

**Purpose:** Custom validations

**Examples:**
- URL format validators (already in models)
- Custom business rule validators

### Concerns
**Location:** `app/models/concerns/` or `app/controllers/concerns/`

**Purpose:** Shared behavior

**Examples:**
- Sluggable concern (for FriendlyId)
- Searchable concern (for filtering)

---

## Third-Party Integrations

### Google Services

**Google Calendar:**
- URL generation in EventsHelper
- No API key required for "Add to Calendar" links

**Google Maps:**
- Embed URL generation in EventsHelper
- No API key required for basic embeds
- Uses standard embed format

**Google Places:**
- Autocomplete API in PlacesController
- API key required (stored in credentials)

---

## Utilities

### SVG Icon System

**Location:** `app/assets/icons/`

**Icons:**
- `google_calendar.svg` - Calendar icon
- Social media icons (Strava, TrailForks, etc.)

**Rendering:**
- `inline_svg` helper in ApplicationHelper
- Inline rendering for styling flexibility
- CSS classes can be added dynamically

**Benefits:**
- No external icon library needed
- Full CSS control
- No HTTP requests
- Customizable per-instance

---

## Date/Time Utilities

**Rails Built-ins:**
- `time_ago_in_words` - Relative time display
- `distance_of_time_in_words` - Time duration
- `l` (localize) - Formatted dates

**Strftime Formats:**
Used in google_calendar_url:
- `%Y%m%dT%H%M%S` - Google Calendar format

**Timezone Handling:**
- Rails default timezone (UTC)
- User timezone (if implemented)

---

## URL Helpers

**Rails Built-ins:**
- All route helpers (e.g., `club_path`, `events_path`)
- `url_for` - Generic URL generation
- `link_to` - Link generation

**Custom:**
- `google_calendar_url` - External calendar link
- `google_maps_embed_url` - Map embed URL

---

## Text Processing

### HTML Sanitization

**EventsHelper uses:**
- `strip_tags` - Remove HTML tags (for Google Calendar description)
- From `ActionView::Helpers::SanitizeHelper`

**Other Available:**
- `sanitize` - Allow safe HTML
- `sanitize_css` - CSS sanitization

---

## Code Organization

### Helper Method Naming

**Conventions:**
- Verb + noun (e.g., `google_calendar_url`)
- Descriptive names
- Return type in name when ambiguous

**Examples:**
- `inline_svg` - Returns SVG string
- `google_calendar_url` - Returns URL string
- `google_maps_embed_url` - Returns embeddable URL

### Module Structure

**Pattern:**
```ruby
module EventsHelper
  include OtherHelper # If needed

  def helper_method(argument)
    # Implementation
  end

  private

  def private_helper
    # Not accessible in views
  end
end
```

---

## Testing Helpers

**Helper Specs:**
**Location:** `spec/helpers/`

**Current State:** Not present (testing helpers via integration tests)

**Potential Tests:**
- `inline_svg` rendering
- `google_calendar_url` format
- `google_maps_embed_url` parsing

**Testing Pattern:**
```ruby
RSpec.describe EventsHelper, type: :helper do
  describe '#google_calendar_url' do
    it 'generates correct URL' do
      event = create(:event)
      url = helper.google_calendar_url(event)
      expect(url).to include('calendar.google.com')
    end
  end
end
```

---

## Future Enhancements

### Potential Additions

**Service Objects:**
- Complex workflows
- External API integrations
- Background job coordination

**Decorators/Presenters:**
- View object pattern
- Cleaner view logic
- Testable presentation layer

**Form Objects:**
- Multi-model forms
- Complex form logic
- Validation composition

**Query Objects:**
- Complex database queries
- Reusable query logic
- Chainable filters

**Policy Objects:**
- Authorization logic (if not using Pundit)
- Permission checks
- Access control

---

## Documentation

**Inline Documentation:**
- Comments in EventsHelper explain URL formats
- Helper methods have descriptive names

**README:**
- No lib-specific README currently
- Could add documentation for complex helpers

---

## Performance Considerations

### Helper Optimization

**SVG Inlining:**
- File read on each call
- Could be cached for production
- Small files, minimal impact

**URL Generation:**
- String interpolation
- No database queries
- Fast execution

**Best Practices:**
- Avoid database queries in helpers
- Cache expensive computations
- Use memoization for repeated calls

---

## Security Considerations

### SVG Safety
- Files are server-controlled
- No user-uploaded SVGs inlined
- Safe for XSS

### URL Generation
- `CGI.escape` for user input
- URI parsing with error handling
- No injection vulnerabilities

### HTML Safety
- `html_safe` used appropriately
- `strip_tags` prevents HTML in external APIs
- Sanitization where needed
