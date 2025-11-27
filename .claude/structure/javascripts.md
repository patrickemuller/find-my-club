# JavaScript

This document provides a breakdown of all JavaScript code in the Find My Club application.

## Overview

The application uses **Hotwire** (Turbo + Stimulus) for JavaScript interactivity, following a progressive enhancement approach.

## Main Entry Point

**File:** `app/javascript/application.js`

Imports:
- `@hotwired/turbo-rails` - Turbo Drive, Frames, and Streams
- `controllers` - Stimulus controllers (auto-loaded)
- `trix` - Rich text editor
- `@rails/actiontext` - ActionText integration

---

## Stimulus Controllers

**Directory:** `app/javascript/controllers/`

All controllers are auto-registered via the Stimulus controller index.

### Application Controller
**File:** `controllers/application.js`
- Base Stimulus application setup
- Imports and configures Stimulus

### Index
**File:** `controllers/index.js`
- Auto-loads all Stimulus controllers
- Registers controllers with the Stimulus application

---

## Feature Controllers

### Calendar Controller
**File:** `controllers/calendar_controller.js`

**Purpose:** Interactive monthly calendar view for club events

**Targets:**
- `monthDisplay` - Current month/year display
- `grid` - Calendar grid container

**Values:**
- `events: Array` - Array of event objects with name, starts_at, url

**Key Methods:**
- `connect()` - Initialize calendar with current month
- `previousMonth()` - Navigate to previous month
- `nextMonth()` - Navigate to next month
- `goToToday()` - Jump to current month
- `renderCalendar()` - Generate calendar HTML
- `renderDayCell(dayNum, date, events, isCurrentMonth, isToday)` - Render individual day
- `getEventsForDate(dateStr)` - Filter events by date
- `formatDateISO(date)` - Format date as YYYY-MM-DD
- `formatTime(datetimeStr)` - Format time as 12-hour with AM/PM
- `isToday(date)` - Check if date is today
- `escapeHtml(text)` - Sanitize HTML

**Features:**
- Month navigation (previous/next/today)
- Shows up to 2 events per day
- "+N more" indicator for days with >2 events
- Highlights today's date
- Dark mode support
- Responsive design

---

### Places Autocomplete Controller
**File:** `controllers/places_autocomplete_controller.js`

**Purpose:** Location search with autocomplete for event creation

**Targets:**
- `input` - Search input field
- `hiddenField` - Hidden field for Google Maps URL
- `nameField` - Hidden field for location name
- `results` - Results dropdown container

**Key Methods:**
- `connect()` - Initialize autocomplete, create results container
- `setupEventListeners()` - Keyboard and click handlers
- `fetchPredictions(query)` - Fetch location suggestions from API
- `displayPredictions(predictions)` - Show results dropdown
- `selectPrediction(prediction)` - Handle location selection
- `handleKeydown(e)` - Keyboard navigation (arrows, enter, escape)
- `highlightItem(items)` - Visual highlight for selected item

**Features:**
- 300ms debounced search
- Keyboard navigation (arrows, enter, escape)
- Click outside to close
- Dark mode support
- Integrates with `/places/autocomplete` API endpoint
- Generates Google Maps embeddable URLs

---

### Carousel Controller
**File:** `controllers/carousel_controller.js`

**Purpose:** Image/content carousel component

**Targets:**
- (Defined in controller implementation)

**Features:**
- Slide navigation
- Auto-play functionality
- Touch/swipe support

---

### Dropdown Controller
**File:** `controllers/dropdown_controller.js`

**Purpose:** Generic dropdown menu component

**Features:**
- Toggle open/close
- Click outside to close
- Keyboard accessibility

---

### Mobile Menu Controller
**File:** `controllers/mobile_menu_controller.js`

**Purpose:** Responsive mobile navigation menu

**Features:**
- Toggle menu visibility
- Overlay/modal behavior
- Touch-friendly interactions

---

### Participants Modal Controller
**File:** `controllers/participants_modal_controller.js`

**Purpose:** Modal dialog for viewing event participants

**Features:**
- Show/hide modal
- List confirmed participants
- Show waitlist if applicable
- Owner actions (approve, etc.)

---

### Tabs Controller
**File:** `controllers/tabs_controller.js`

**Purpose:** Tabbed interface component

**Features:**
- Switch between tab panels
- Active state management
- Keyboard navigation
- Used for: upcoming/past events, owned/joined clubs

---

### Theme Toggle Controller
**File:** `controllers/theme_toggle_controller.js`

**Purpose:** Dark mode toggle

**Features:**
- Switch between light/dark themes
- Persist preference to localStorage
- Respect system preferences
- Smooth transitions

---

### Tooltip Controller
**File:** `controllers/tooltip_controller.js`

**Purpose:** Interactive tooltips

**Features:**
- Show on hover
- Positioning logic
- Accessible implementation

---

### Hello Controller
**File:** `controllers/hello_controller.js`

**Purpose:** Example/demo controller (can be removed in production)

**Features:**
- Basic Stimulus demonstration
- Likely not used in production code

---

## JavaScript Patterns

### Stimulus Best Practices
- Controllers are scoped to DOM elements via `data-controller`
- Targets defined with `data-{controller}-target`
- Values passed via `data-{controller}-{value}-value`
- Actions triggered with `data-action`

### API Integration
- Fetch API for AJAX requests
- JSON responses from Rails endpoints
- CSRF token handling via Turbo

### Progressive Enhancement
- JavaScript enhances base HTML
- Falls back gracefully without JS
- Server-side rendering first

### Dark Mode
- Controllers respect dark mode CSS classes
- Consistent dark mode support across components
- Theme persistence in localStorage

---

## Import Maps

**File:** `config/importmap.rb`

Manages JavaScript dependencies without bundling:
- `@hotwired/turbo-rails`
- `@hotwired/stimulus`
- `trix`
- `@rails/actiontext`
- All custom Stimulus controllers

---

## Hotwire Integration

### Turbo Drive
- SPA-like navigation without full page reloads
- Preserves scroll position
- Progress bar for navigation

### Turbo Frames
- Partial page updates
- Lazy loading content
- Used for modals, dropdowns

### Turbo Streams
- Real-time updates over WebSockets
- Server-sent HTML updates
- Used for: form responses, flash messages

---

## Event Handling

**Common Events:**
- `turbo:load` - Page loaded via Turbo
- `turbo:frame-load` - Frame loaded
- `turbo:submit-start` - Form submission started
- `turbo:submit-end` - Form submission completed

**Custom Events:**
- Controllers dispatch custom events for cross-component communication
- Events bubble up the DOM for parent controllers to handle

---

## Code Organization

**Structure:**
```
app/javascript/
├── application.js          # Entry point
└── controllers/
    ├── application.js      # Stimulus app config
    ├── index.js           # Controller registration
    ├── calendar_controller.js
    ├── places_autocomplete_controller.js
    ├── carousel_controller.js
    ├── dropdown_controller.js
    ├── mobile_menu_controller.js
    ├── participants_modal_controller.js
    ├── tabs_controller.js
    ├── theme_toggle_controller.js
    ├── tooltip_controller.js
    └── hello_controller.js
```

**Naming Conventions:**
- Controller files: `{name}_controller.js`
- Controller classes: PascalCase extending Controller
- Targets: camelCase
- Actions: camelCase methods

---

## Testing

JavaScript testing approach:
- System specs with Capybara test JavaScript behavior
- Stimulus controllers tested via integration tests
- No separate JavaScript unit tests currently

---

## Performance Considerations

- Debouncing on autocomplete (300ms)
- Lazy loading with Turbo Frames
- Minimal JavaScript footprint
- Import maps for HTTP/2 efficiency
- No build step required for development
