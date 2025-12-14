# Models

This document provides a breakdown of all models in the Find My Club application.

## Core Models

### User
**File:** `app/models/user.rb`
**Table:** `users`

**Description:** Represents application users with authentication via Devise.

**Key Attributes:**
- `email` - User email (unique, required)
- `encrypted_password` - Devise authentication
- `first_name`, `last_name` - User name (required)
- `admin` - Admin flag (boolean, default: false)
- `strava_url` - Strava profile URL (validated format)
- `trailforks_url` - TrailForks profile URL (validated format)
- `outside_url` - Outside.com profile URL (validated format)
- `athlinks_url` - Athlinks profile URL (validated format)
- Devise fields: confirmation, trackable, rememberable, recoverable

**Associations:**
- `has_many :clubs` (as owner, foreign_key: :owner_id)
- `has_many :memberships`
- `has_many :clubs_as_member` (through memberships)
- `has_many :event_registrations`

**Key Methods:**
- `member_of?(club)` - Check if user is active member of club
- `can_join?(club)` - Check if user can join a club
- `strava_username` - Extract username from Strava URL
- `trailforks_username` - Extract username from TrailForks URL
- `outside_username` - Extract username from Outside.com URL
- `athlinks_username` - Extract username from Athlinks URL

**Validations:**
- Required: email, password, first_name, last_name
- URL format validation for all social media URLs
- Custom validation to prevent XSS in URLs

---

### Club
**File:** `app/models/club.rb`
**Table:** `clubs`

**Description:** Represents sports clubs that users can create and join.

**Key Attributes:**
- `name` - Club name (required, unique slug)
- `slug` - URL-friendly identifier (auto-generated from name)
- `category` - Sport category (required, from predefined list)
- `level` - Skill level (required, from predefined list)
- `public` - Visibility flag (boolean, default: false)
- `active` - Enable/disable flag (boolean, default: true)
- `owner_id` - Reference to User who owns the club

**Constants:**
- `LEVELS_FOR_SELECT` - Beginner, Intermediate, Advanced, Expert
- `CATEGORIES_FOR_SELECT` - Team Ball Sports, Racket Sports, Combat Sports, Aquatic Sports, Athletics, Winter Sports, Cycling Sports, Other

**Associations:**
- `belongs_to :owner` (class_name: "User")
- `has_many :memberships`
- `has_many :members` (through memberships, source: :user)
- `has_many :events`
- `has_rich_text :description`
- `has_rich_text :rules`

**Scopes:**
- `publicly_visible` - Only public clubs
- `search(search)` - Search by name (case-insensitive)
- `with_category(categories)` - Filter by categories
- `with_level(level)` - Filter by level

**Key Methods:**
- `private?` - Check if club is private
- `is_owner?(user)` - Check if user is the owner
- `disabled?` - Check if club is disabled
- `formatted_category` - Human-readable category
- `formatted_level` - Human-readable level
- `members_count` - Count of active members
- `has_member?(user)` - Check if user is active member

---

### Membership
**File:** `app/models/membership.rb`
**Table:** `memberships`

**Description:** Join table representing user membership in clubs.

**Key Attributes:**
- `user_id` - Reference to User
- `club_id` - Reference to Club
- `status` - Membership status (active, pending, disabled)
- `role` - Membership role (currently only "member")

**Associations:**
- `belongs_to :user`
- `belongs_to :club`

**Enums:**
- `status`: active, pending, disabled
- `role`: member

**Scopes:**
- `active` - Only active memberships
- `pending` - Only pending memberships
- `disabled` - Only disabled memberships

**Validations:**
- Unique user per club
- Owner cannot be member of their own club

---

### Event
**File:** `app/models/event.rb`
**Table:** `events`

**Description:** Represents scheduled events within clubs.

**Key Attributes:**
- `name` - Event name (required, unique slug)
- `slug` - URL-friendly identifier (auto-generated from name)
- `location` - Geographic coordinates/address (required)
- `location_name` - Human-readable location name (required)
- `starts_at` - Event start datetime (required, must be in future)
- `ends_at` - Event end datetime (required, must be after starts_at)
- `max_participants` - Maximum attendees (required, min: 2)
- `has_waitlist` - Enable waitlist (boolean, default: false)
- `club_id` - Reference to Club

**Associations:**
- `belongs_to :club`
- `has_many :event_registrations`
- `has_many :participants` (through event_registrations, source: :user)
- `has_rich_text :description`

**Scopes:**
- `upcoming` - Events starting in the future (ordered by starts_at ASC)
- `past` - Events that have started (ordered by starts_at DESC)

**Key Methods:**
- `in_progress?` - Check if event hasn't started yet
- `full?` - Check if all spots are taken
- `confirmed_participants_count` - Count of confirmed registrations
- `waitlist_participants_count` - Count of waitlist registrations
- `available_spots` - Number of remaining spots
- `user_registered?(user)` - Check if user is registered
- `user_registration_status(user)` - Get user's registration status

**Validations:**
- ends_at must be after starts_at
- starts_at must be in future (on create)
- max_participants must be >= 2

---

### EventRegistration
**File:** `app/models/event_registration.rb`
**Table:** `event_registrations`

**Description:** Join table representing user registration for events.

**Key Attributes:**
- `user_id` - Reference to User
- `event_id` - Reference to Event
- `status` - Registration status (confirmed, waitlist)

**Associations:**
- `belongs_to :event`
- `belongs_to :user`

**Enums:**
- `status`: confirmed, waitlist

**Scopes:**
- `confirmed` - Only confirmed registrations
- `waitlist` - Only waitlist registrations

**Validations:**
- Unique user per event
- User must be club member to register
- Owner cannot register (automatically participant)

---

### Invoice
**File:** `app/models/invoice.rb`
**Table:** `invoices`

**Description:** Stores payment invoice records from Stripe webhooks.

**Key Attributes:**
- `user_id` - Reference to User
- `stripe_invoice_id` - Stripe invoice ID (unique)
- `stripe_subscription_id` - Stripe subscription ID
- `club_name` - Snapshot of club name at payment time
- `amount_cents` - Payment amount in cents
- `currency` - Currency code
- `status` - Invoice status
- `invoice_number` - Stripe invoice number
- `invoice_pdf_url` - URL to downloadable PDF
- `period_start` - Billing period start
- `period_end` - Billing period end
- `paid_at` - Payment timestamp

**Associations:**
- `belongs_to :user`

**Key Methods:**
- `amount_in_dollars` - Returns amount in dollars

**Validations:**
- Required: stripe_invoice_id (unique), club_name, amount_cents, currency, status

**Notes:**
- Stores immutable snapshot of payment data
- Club name copied at invoice creation time
- Created automatically via Stripe webhooks

---

## Support Models

### ApplicationRecord
**File:** `app/models/application_record.rb`
- Base class for all models
- Inherits from `ActiveRecord::Base`

---

## Mailers

### ApplicationMailer
**File:** `app/mailers/application_mailer.rb`
- Base mailer class
- Default from address and layout

### MembershipMailer
**File:** `app/mailers/membership_mailer.rb`
- Handles membership-related emails
- Methods:
  - Membership approval notifications
  - Membership request notifications

---

## Jobs

### ApplicationJob
**File:** `app/jobs/application_job.rb`
- Base job class
- Inherits from `ActiveJob::Base`

---

## Database Features

**Rich Text (ActionText):**
- Club: description, rules
- Event: description

**Friendly URLs (FriendlyId):**
- Club: slug based on name
- Event: slug based on name

**File Storage (ActiveStorage):**
- Configured for CloudFlare R2 in production
- Can be used for user avatars, club logos, event images

**Background Jobs (SolidQueue):**
- Rails 8 default queue adapter
- All job-related tables in schema

---

## Data Relationships

```
User
├── owns many Clubs (as owner)
├── has many Memberships
│   └── through: clubs_as_member
├── has many EventRegistrations
└── has many Invoices

Club
├── belongs to owner (User)
├── has many Memberships
│   └── through: members (Users)
└── has many Events

Event
├── belongs to Club
└── has many EventRegistrations
    └── through: participants (Users)

Membership
├── belongs to User
└── belongs to Club

EventRegistration
├── belongs to User
└── belongs to Event
```