# Views

This document provides a breakdown of all view templates in the Find My Club application.

## Layout Templates

### Application Layout
**File:** `app/views/layouts/application.html.erb`
- Main application layout
- Includes header, flash messages, breadcrumbs, and footer
- Renders yield for page content
- Configured for Hotwire (Turbo/Stimulus)

### Mailer Layout
**File:** `app/views/layouts/mailer.html.erb`
- HTML email layout
- Used for all email templates

### ActionText Layout
**File:** `app/views/layouts/action_text/contents/_content.html.erb`
- Rich text content rendering
- Used for club descriptions, rules, event descriptions

---

## Pages Views

### Home Page
**File:** `app/views/pages/home.html.erb`
- Landing page
- Root path (/)
- Marketing/welcome content

---

## Clubs Views

**Directory:** `app/views/clubs/`

### Index
**File:** `index.html.erb`
- Lists all public clubs
- Includes search and filter functionality
- Shows club cards with key info

### Show
**File:** `show.html.erb`
- Individual club details page
- Displays description, rules, events
- Join/leave buttons for users
- Management actions for owners

### New
**File:** `new.html.erb`
- Form to create new club
- Renders `_form.html.erb` partial

### Edit
**File:** `edit.html.erb`
- Form to edit existing club
- Renders `_form.html.erb` partial
- Only accessible to club owner

### My Clubs
**File:** `my_clubs.html.erb`
- Shows clubs user owns or is member of
- Tabs for "Owned" and "Joined" clubs

### Members
**File:** `members.html.erb`
- Lists all club members
- Shows pending membership requests
- Owner-only view with approve/disable actions

### Partials

**`_club.html.erb`**
- Club card component
- Used in index and my_clubs views
- Shows club preview with name, category, level, member count

**`_form.html.erb`**
- Shared form for new/edit club
- Includes fields for name, category, level, description, rules

---

## Events Views

**Directory:** `app/views/events/`

### Index
**File:** `index.html.erb`
- Lists all events for a club
- Tabs for upcoming and past events
- Calendar view integration

### Show
**File:** `show.html.erb`
- Individual event details
- Registration button for members
- Participant list
- Waitlist if applicable

### New
**File:** `new.html.erb`
- Form to create new event
- Renders `_form.html.erb` partial

### Edit
**File:** `edit.html.erb`
- Form to edit existing event
- Renders `_form.html.erb` partial
- Only accessible to club owner

### Registrations
**File:** `registrations.html.erb`
- Owner view of all event registrations
- Shows confirmed and waitlist participants
- Approve/manage waitlist actions

### Partials

**`_event_card.html.erb`**
- Event card component
- Shows event preview with date, location, participants

**`_calendar.html.erb`**
- Calendar view of events
- Integrated with Stimulus calendar controller
- Shows events by month/week/day

**`_form.html.erb`**
- Shared form for new/edit event
- Includes fields for name, description, location, dates, max participants
- Places autocomplete integration

---

## Users Views

**Directory:** `app/views/users/`

### Profiles

**Directory:** `users/profiles/`

**`show.html.erb`**
- User profile page
- Shows user info and social media links
- Displays clubs user is member of
- Profile carousel with images

### Subscriptions

**Directory:** `users/subscriptions/`

**`index.html.erb`**
- User subscriptions page
- Shows all paid club memberships
- Displays club name (linked to club page), plan name, and pricing
- Shows member since date

### Registrations (Devise)

**Directory:** `users/registrations/`

**`new.html.erb`**
- Sign up form
- First name, last name, email, password

**`edit.html.erb`**
- Edit profile form
- Update email, password, social media URLs
- Links to Strava, TrailForks, Outside.com, Athlinks

### Sessions (Devise)

**Directory:** `users/sessions/`

**`new.html.erb`**
- Sign in form
- Email and password
- Remember me checkbox

### Passwords (Devise)

**Directory:** `users/passwords/`

**`new.html.erb`**
- Forgot password form
- Sends reset instructions

**`edit.html.erb`**
- Reset password form
- Set new password

### Confirmations (Devise)

**Directory:** `users/confirmations/`

**`new.html.erb`**
- Resend confirmation instructions

### Unlocks (Devise)

**Directory:** `users/unlocks/`

**`new.html.erb`**
- Resend unlock instructions

### Mailer Templates

**Directory:** `users/mailer/`

- `confirmation_instructions.html.erb` - Email confirmation
- `reset_password_instructions.html.erb` - Password reset
- `password_change.html.erb` - Password changed notification
- `email_changed.html.erb` - Email changed notification
- `unlock_instructions.html.erb` - Account unlock

### Shared Partials

**Directory:** `users/shared/`

**`_error_messages.html.erb`**
- Form error display
- Used across all Devise forms

**`_links.html.erb`**
- Devise navigation links
- Sign in, sign up, forgot password, etc.

---

## Membership Mailer Views

**Directory:** `app/views/membership_mailer/`

**`approved.html.erb`**
- Email sent when membership is approved
- Notifies user they can now access the club

---

## Shared Views

**Directory:** `app/views/shared/`

### Header
**File:** `_header.html.erb`
- Navigation bar
- User menu (sign in/sign out)
- Mobile responsive menu
- Links to clubs, my clubs

### Footer
**File:** `_footer.html.erb`
- Site footer
- Links and copyright

### Flash Messages
**File:** `_flash_messages.html.erb`
- Displays alerts, notices, errors
- Styled for different message types
- Auto-dismiss functionality

### Breadcrumbs
**File:** `_breadcrumbs.html.erb`
- Navigation breadcrumb trail
- Shows current page hierarchy

### Tooltip
**File:** `_tooltip.html.erb`
- Tooltip component
- Used across the app for helpful hints

---

## Pagination Views (Kaminari)

**Directory:** `app/views/kaminari/`

Custom pagination templates:
- `_paginator.html.erb` - Main paginator wrapper
- `_first_page.html.erb` - First page link
- `_prev_page.html.erb` - Previous page link
- `_page.html.erb` - Individual page number
- `_next_page.html.erb` - Next page link
- `_last_page.html.erb` - Last page link
- `_gap.html.erb` - Ellipsis between pages

---

## ActiveStorage Views

**Directory:** `app/views/active_storage/blobs/`

**`_blob.html.erb`**
- File attachment display
- Used for uploaded files in ActionText

---

## View Patterns

**Styling:**
- All views use Tailwind CSS for styling
- Dark mode support throughout
- Responsive mobile-first design

**Components:**
- Heavy use of partials for reusable components
- Card-based layouts for clubs and events
- Modal dialogs for interactive actions

**Interactivity:**
- Hotwire Turbo for navigation
- Stimulus controllers for JavaScript behavior
- Progressive enhancement approach

**Forms:**
- Rails form helpers
- Error message display
- Accessible form labels and inputs

**Navigation:**
- Breadcrumbs on detail pages
- Header with main navigation
- Tab-based interfaces for content organization
