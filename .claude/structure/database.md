# Database

This document provides a breakdown of the database structure for the Find My Club application.

## Database Overview

**DBMS:** PostgreSQL
**Schema Version:** 2025_11_04_044558
**Schema File:** `db/schema.rb`

---

## Core Tables

### Users Table

**Table:** `users`

**Purpose:** Store user accounts with authentication

**Columns:**
- `id` (bigint, PK) - Primary key
- `email` (string, unique, required) - User email
- `encrypted_password` (string, required) - Hashed password
- `first_name` (string, required) - User's first name
- `last_name` (string, required) - User's last name
- `phone_number` (string, required) - Phone number in E.164 format
- `country_code` (string, required) - ISO country code for phone validation
- `admin` (boolean, default: false) - Admin flag
- `strava_url` (string) - Strava profile URL
- `trailforks_url` (string) - TrailForks profile URL
- `outside_url` (string) - Outside.com profile URL
- `athlinks_url` (string) - Athlinks profile URL

**Devise Fields:**
- `reset_password_token` (string, unique) - Password reset token
- `reset_password_sent_at` (datetime) - Reset email timestamp
- `remember_created_at` (datetime) - Remember me token timestamp
- `sign_in_count` (integer, default: 0) - Login counter
- `current_sign_in_at` (datetime) - Current login time
- `last_sign_in_at` (datetime) - Last login time
- `current_sign_in_ip` (string) - Current IP address
- `last_sign_in_ip` (string) - Last IP address
- `confirmation_token` (string, unique) - Email confirmation token
- `confirmed_at` (datetime) - Confirmation timestamp
- `confirmation_sent_at` (datetime) - Confirmation email timestamp
- `unconfirmed_email` (string) - Pending email change

**Timestamps:**
- `created_at` (datetime)
- `updated_at` (datetime)

**Indexes:**
- `index_users_on_email` (unique)
- `index_users_on_reset_password_token` (unique)
- `index_users_on_confirmation_token` (unique)

---

### Clubs Table

**Table:** `clubs`

**Purpose:** Store sports clubs created by users

**Columns:**
- `id` (bigint, PK) - Primary key
- `name` (string, required) - Club name
- `slug` (string, unique) - URL-friendly slug
- `category` (string, required) - Sport category
- `level` (string, required) - Skill level
- `owner_id` (bigint, FK, required) - References users.id
- `public` (boolean, default: false) - Visibility flag
- `active` (boolean, default: true) - Enable/disable flag
- `created_at` (datetime)
- `updated_at` (datetime)

**Rich Text (ActionText):**
- `description` - Stored in action_text_rich_texts table
- `rules` - Stored in action_text_rich_texts table

**Indexes:**
- `index_clubs_on_owner_id`
- `index_clubs_on_slug` (unique)

**Foreign Keys:**
- `owner_id` → `users.id`

---

### Memberships Table

**Table:** `memberships`

**Purpose:** Join table connecting users to clubs

**Columns:**
- `id` (bigint, PK) - Primary key
- `user_id` (bigint, FK, required) - References users.id
- `club_id` (bigint, FK, required) - References clubs.id
- `status` (string, default: "active", required) - Membership status
- `role` (string, default: "member", required) - Membership role
- `created_at` (datetime)
- `updated_at` (datetime)

**Enums:**
- `status`: active, pending, disabled
- `role`: member

**Indexes:**
- `index_memberships_on_user_id`
- `index_memberships_on_club_id`
- `index_memberships_on_user_id_and_club_id` (unique)
- `index_memberships_on_status`
- `index_memberships_on_role`

**Foreign Keys:**
- `user_id` → `users.id`
- `club_id` → `clubs.id`

**Constraints:**
- Unique combination of user_id and club_id
- Owner cannot be a member of their own club (model validation)

---

### Events Table

**Table:** `events`

**Purpose:** Store scheduled events within clubs

**Columns:**
- `id` (bigint, PK) - Primary key
- `name` (string, required) - Event name
- `slug` (string, unique) - URL-friendly slug
- `location` (string, required) - Geographic coordinates/address
- `location_name` (string, required) - Human-readable location
- `starts_at` (datetime, required) - Event start time
- `ends_at` (datetime, required) - Event end time
- `max_participants` (integer, default: 10, required) - Participant limit
- `has_waitlist` (boolean, default: false, required) - Waitlist enabled
- `club_id` (bigint, FK, required) - References clubs.id
- `created_at` (datetime)
- `updated_at` (datetime)

**Rich Text (ActionText):**
- `description` - Stored in action_text_rich_texts table

**Indexes:**
- `index_events_on_club_id`
- `index_events_on_slug` (unique)

**Foreign Keys:**
- `club_id` → `clubs.id`

**Validations (Model):**
- starts_at must be in the future (on create)
- ends_at must be after starts_at
- max_participants must be >= 2

---

### Event Registrations Table

**Table:** `event_registrations`

**Purpose:** Join table connecting users to event attendance

**Columns:**
- `id` (bigint, PK) - Primary key
- `user_id` (bigint, FK, required) - References users.id
- `event_id` (bigint, FK, required) - References events.id
- `status` (string, default: "confirmed", required) - Registration status
- `created_at` (datetime)
- `updated_at` (datetime)

**Enums:**
- `status`: confirmed, waitlist

**Indexes:**
- `index_event_registrations_on_user_id`
- `index_event_registrations_on_event_id`
- `index_event_registrations_on_user_id_and_event_id` (unique)

**Foreign Keys:**
- `user_id` → `users.id`
- `event_id` → `events.id`

**Constraints:**
- Unique combination of user_id and event_id
- User must be club member (model validation)
- Owner cannot register (auto-participant, model validation)

---

## Supporting Tables

### FriendlyId Slugs

**Table:** `friendly_id_slugs`

**Purpose:** Track slug history for FriendlyId gem

**Columns:**
- `id` (bigint, PK) - Primary key
- `slug` (string, required) - URL slug
- `sluggable_id` (integer, required) - Record ID
- `sluggable_type` (string, limit: 50) - Model type
- `scope` (string) - Slug scope
- `created_at` (datetime)

**Indexes:**
- `index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope` (unique)
- `index_friendly_id_slugs_on_slug_and_sluggable_type`
- `index_friendly_id_slugs_on_sluggable_type_and_sluggable_id`

**Used By:**
- Clubs (slug based on name)
- Events (slug based on name)

---

### ActionText Rich Texts

**Table:** `action_text_rich_texts`

**Purpose:** Store rich text content for ActionText

**Columns:**
- `id` (bigint, PK) - Primary key
- `name` (string, required) - Field name
- `body` (text) - Rich text content
- `record_type` (string, required) - Polymorphic type
- `record_id` (bigint, required) - Polymorphic ID
- `created_at` (datetime)
- `updated_at` (datetime)

**Indexes:**
- `index_action_text_rich_texts_uniqueness` (unique on record_type, record_id, name)

**Used By:**
- Club descriptions
- Club rules
- Event descriptions

---

## ActiveStorage Tables

### Active Storage Blobs

**Table:** `active_storage_blobs`

**Purpose:** Store file metadata

**Columns:**
- `id` (bigint, PK) - Primary key
- `key` (string, unique, required) - Storage key
- `filename` (string, required) - Original filename
- `content_type` (string) - MIME type
- `metadata` (text) - Additional metadata
- `byte_size` (bigint, required) - File size
- `checksum` (string) - File checksum
- `service_name` (string, required) - Storage service (local, cloudflare_r2)
- `created_at` (datetime)

**Indexes:**
- `index_active_storage_blobs_on_key` (unique)

---

### Active Storage Attachments

**Table:** `active_storage_attachments`

**Purpose:** Link files to records

**Columns:**
- `id` (bigint, PK) - Primary key
- `name` (string, required) - Attachment name
- `record_type` (string, required) - Polymorphic type
- `record_id` (bigint, required) - Polymorphic ID
- `blob_id` (bigint, FK, required) - References active_storage_blobs.id
- `created_at` (datetime)

**Indexes:**
- `index_active_storage_attachments_on_blob_id`
- `index_active_storage_attachments_uniqueness` (unique on record_type, record_id, name, blob_id)

**Foreign Keys:**
- `blob_id` → `active_storage_blobs.id`

---

### Active Storage Variant Records

**Table:** `active_storage_variant_records`

**Purpose:** Store image variant information

**Columns:**
- `id` (bigint, PK) - Primary key
- `blob_id` (bigint, FK, required) - References active_storage_blobs.id
- `variation_digest` (string, required) - Variant identifier
- `created_at` (datetime)

**Indexes:**
- `index_active_storage_variant_records_uniqueness` (unique on blob_id, variation_digest)

**Foreign Keys:**
- `blob_id` → `active_storage_blobs.id`

---

## SolidQueue Tables

### Solid Queue Jobs

**Table:** `solid_queue_jobs`

**Purpose:** Store background job queue

**Columns:**
- `id` (bigint, PK) - Primary key
- `queue_name` (string, required) - Queue name
- `class_name` (string, required) - Job class
- `arguments` (text) - Serialized arguments
- `priority` (integer, default: 0, required) - Job priority
- `active_job_id` (string) - ActiveJob ID
- `scheduled_at` (datetime) - Scheduled time
- `finished_at` (datetime) - Completion time
- `concurrency_key` (string) - Concurrency limit key
- `created_at` (datetime)
- `updated_at` (datetime)

**Indexes:**
- `index_solid_queue_jobs_on_active_job_id`
- `index_solid_queue_jobs_on_class_name`
- `index_solid_queue_jobs_on_finished_at`
- `index_solid_queue_jobs_for_filtering` (queue_name, finished_at)
- `index_solid_queue_jobs_for_alerting` (scheduled_at, finished_at)

---

### Solid Queue Processes

**Table:** `solid_queue_processes`

**Purpose:** Track job worker processes

**Columns:**
- `id` (bigint, PK) - Primary key
- `kind` (string, required) - Process type
- `name` (string, required) - Process name
- `hostname` (string) - Server hostname
- `pid` (integer, required) - Process ID
- `supervisor_id` (bigint, FK) - Parent supervisor
- `last_heartbeat_at` (datetime, required) - Heartbeat timestamp
- `metadata` (text) - Additional data
- `created_at` (datetime)

**Indexes:**
- `index_solid_queue_processes_on_name_and_supervisor_id` (unique)
- `index_solid_queue_processes_on_supervisor_id`
- `index_solid_queue_processes_on_last_heartbeat_at`

---

### Other SolidQueue Tables

- `solid_queue_blocked_executions` - Blocked jobs
- `solid_queue_claimed_executions` - Claimed jobs
- `solid_queue_failed_executions` - Failed jobs
- `solid_queue_ready_executions` - Ready to run jobs
- `solid_queue_scheduled_executions` - Scheduled jobs
- `solid_queue_recurring_executions` - Recurring job runs
- `solid_queue_recurring_tasks` - Recurring task definitions
- `solid_queue_pauses` - Paused queues
- `solid_queue_semaphores` - Concurrency control

---

## Migrations

**Directory:** `db/migrate/`

**Migration History:**

1. `20250913010632` - Move SolidCable to single database
2. `20250914203542` - Devise create users
3. `20250915005342` - Create clubs
4. `20250915010937` - Add slug to clubs
5. `20250915010946` - Create FriendlyId slugs
6. `20251021232145` - Create memberships
7. `20251022023738` - Create ActiveStorage tables
8. `20251022023739` - Create ActionText tables
9. `20251022023820` - Migrate club content to ActionText
10. `20251022023944` - Remove description and rules from clubs
11. `20251024230357` - Create events
12. `20251024230431` - Create event registrations
13. `20251104044558` - Add social media links to users
14. `20251125200409` - Create club invitations (recent)

---

## Seeds

**File:** `db/seeds.rb`

**Purpose:** Populate development/staging database with sample data

**Creates:**
- Sample users
- Sample clubs
- Sample memberships
- Sample events
- Sample event registrations

---

## Database Relationships

### Entity Relationship Diagram (ERD)

```
User
├─ has_many :clubs (as owner)
├─ has_many :memberships
│  └─ has_many :clubs (through memberships, as member)
└─ has_many :event_registrations
   └─ has_many :events (through event_registrations)

Club
├─ belongs_to :owner (User)
├─ has_many :memberships
│  └─ has_many :members (Users, through memberships)
├─ has_many :events
└─ has_rich_text :description, :rules

Event
├─ belongs_to :club
├─ has_many :event_registrations
│  └─ has_many :participants (Users, through event_registrations)
└─ has_rich_text :description

Membership
├─ belongs_to :user
└─ belongs_to :club

EventRegistration
├─ belongs_to :user
└─ belongs_to :event
```

---

## Database Constraints

### Unique Constraints
- User email
- Club slug
- Event slug
- User/Club membership combination
- User/Event registration combination

### Foreign Key Constraints
- All associations enforce referential integrity
- Cascading deletes where appropriate

### Check Constraints (Model-level)
- Event ends_at > starts_at
- Event starts_at > current time (on create)
- Max participants >= 2
- Owner cannot be member of own club

---

## Indexes

**Purpose:** Optimize query performance

**Key Indexes:**
- All foreign keys indexed
- Unique slugs indexed
- Email indexed (authentication)
- Status/role fields indexed (filtering)
- Timestamp fields for job queue

---

## Database Tasks

### Common Commands

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback

# Reset database
rails db:reset

# Seed data
rails db:seed

# Drop database
rails db:drop

# Database console
rails db

# Schema dump
rails db:schema:dump
```

### Generate Migration

```bash
# Create migration
rails generate migration AddFieldToTable field:type

# Create model with migration
rails generate model ModelName field:type
```

---

## Database Performance

### Optimization Strategies
- Proper indexing on foreign keys
- Unique indexes on slug fields
- Composite indexes for common queries
- Connection pooling configured
- Query optimization via includes/joins

### Monitoring
- Slow query logging (production)
- Database metrics
- Connection pool monitoring
- Index usage analysis

---

## Backup & Recovery

**Production:**
- Automated daily backups
- Point-in-time recovery available
- Backup retention policy

**Development:**
- `db/schema.rb` tracks schema
- `db/seeds.rb` recreates sample data
- Git tracks migrations
