# Configuration

This document provides a breakdown of all configuration files in the Find My Club application.

## Core Configuration Files

### Application Configuration
**File:** `config/application.rb`

**Module:** `FindMyClub::Application`

**Key Settings:**
- Rails 8.0 defaults loaded
- Autoload lib directory (excludes assets, tasks)
- Standard Rails application setup

---

### Environment Configurations

**Files:**
- `config/environments/development.rb`
- `config/environments/test.rb`
- `config/environments/production.rb`

**Environment-specific settings:**
- Asset compilation
- Caching strategies
- Logging levels
- Error handling
- Email delivery methods
- Active Storage configuration

---

### Routes
**File:** `config/routes.rb`

See the [controllers.md](controllers.md) document for detailed routing information.

**Root:** `pages#home`

**Main Resource Routes:**
- `devise_for :users` - Authentication
- `resources :clubs` - Clubs management
  - Nested: memberships, events
- Event registrations
- Places autocomplete API
- User profiles

---

## Database Configuration

### Database
**File:** `config/database.yml`

**Adapter:** PostgreSQL

**Environments:**

**Development:**
- Database: `find_my_club_development`
- Pool size: 5 (from ENV or default)

**Test:**
- Database: `find_my_club_test`
- Wiped and regenerated on test runs

**Production:**
- URL from `DATABASE_URL` environment variable
- Schema search path: `public, heroku_ext` (Heroku deployment)
- Pool size from `RAILS_MAX_THREADS`

---

### Schema
**File:** `db/schema.rb`

Current schema version: `2025_11_04_044558`

**Tables:**
- users
- clubs
- memberships
- events
- event_registrations
- action_text_rich_texts
- active_storage_* (attachments, blobs, variants)
- friendly_id_slugs
- solid_queue_* (job queue tables)

See [database.md](database.md) for detailed schema information.

---

### Migrations
**Directory:** `db/migrate/`

All database migrations in chronological order. Schema managed through Active Record migrations.

---

### Seeds
**File:** `db/seeds.rb`

Sample data for development/testing environments.

---

## Storage Configuration

### Active Storage
**File:** `config/storage.yml`

**Services Configured:**

**test:**
- Service: Disk
- Location: `tmp/storage`
- Used in test environment

**local:**
- Service: Disk
- Location: `storage/`
- Used in development

**cloudflare_r2:**
- Service: S3 (R2 is S3-compatible)
- Endpoint: from `R2_ENDPOINT` env var
- Access Key: from `R2_ACCESS_KEY` env var
- Secret: from `R2_SECRET_KEY` env var
- Bucket: from `R2_BUCKET_NAME` env var (default: "find-my-club-production")
- Region: auto
- Checksum settings: "when_required" (R2-specific)
- Used in production

**Commented out services:**
- Amazon S3
- Google Cloud Storage
- Azure Storage
- Mirror service

---

## Asset Configuration

### Import Map
**File:** `config/importmap.rb`

**Pinned Packages:**
- `application` - Main JS entry point
- `@hotwired/turbo-rails` → turbo.min.js
- `@hotwired/stimulus` → stimulus.min.js
- `@hotwired/stimulus-loading` → stimulus-loading.js
- All controllers from `app/javascript/controllers/`
- `trix` - Rich text editor
- `@rails/actiontext` → actiontext.esm.js

**No build step required** - Import maps serve files directly via HTTP/2.

---

### Propshaft
**File:** `config/initializers/assets.rb`

Asset pipeline configuration using Propshaft (Rails 8 default).

**Features:**
- No preprocessing
- Fast asset serving
- Content-addressable filenames for caching

---

## Initializers

**Directory:** `config/initializers/`

### Assets
**File:** `assets.rb`
- Asset path configuration
- Precompilation settings

### Content Security Policy
**File:** `content_security_policy.rb`
- CSP headers configuration
- Security policies for assets, scripts, etc.

### Devise
**File:** `devise.rb`

**Authentication Configuration:**
- Mailer sender
- Password complexity
- Session timeout
- Confirmation settings
- Lockable settings
- Trackable settings
- Email validation
- Password encryption (bcrypt)

**Enabled Modules:**
- :database_authenticatable
- :registerable
- :recoverable
- :rememberable
- :validatable
- :confirmable
- :trackable

### Filter Parameter Logging
**File:** `filter_parameter_logging.rb`
- Filters sensitive parameters from logs
- Passwords, tokens, API keys

### FriendlyId
**File:** `friendly_id.rb`

**Configuration:**
- URL slug generation
- Used by Club and Event models
- Base slug length and uniqueness

### Inflections
**File:** `inflections.rb`
- Custom pluralization rules
- Acronyms
- Irregular words

### Kaminari
**File:** `kaminari_config.rb`

**Pagination Configuration:**
- Default items per page
- Window size
- Navigation styles

### Resend
**File:** `resend.rb`

**Email Service:**
- API key from environment
- Used for transactional emails

---

## Locales

**Directory:** `config/locales/`

**Files:**
- `en.yml` - English translations
- Devise locales
- Model/view translations

**I18n Configuration:**
- Default locale: English
- Fallback to default locale

---

## Credentials

### Master Key
**File:** `config/master.key`
- Encrypts credentials file
- **Not committed to git**
- Required for production deployment

### Encrypted Credentials
**File:** `config/credentials.yml.enc`

**Stored Secrets:**
- Database credentials
- API keys
- Service credentials
- Secret key base

**Edit with:**
```bash
EDITOR=vim rails credentials:edit
```

---

## Server Configuration

### Puma
**File:** `config/puma.rb`

**Web Server Settings:**
- Port: 3000 (development)
- Workers: Based on `WEB_CONCURRENCY` env var
- Threads: Min/Max from `RAILS_MAX_THREADS`
- Preload app in production
- Worker timeout
- PID file location

---

## Background Jobs

### Solid Queue
**Files:**
- `config/queue.yml` - Queue configuration
- `config/recurring.yml` - Recurring job schedules

**Job Adapter:** SolidQueue (Rails 8 default)
- Database-backed queue
- No Redis required
- Supervisor process
- Multiple queues support
- Scheduled jobs
- Recurring tasks

---

## Cable (Action Cable)
**File:** `config/cable.yml`

**WebSocket Configuration:**
- Development: async adapter
- Test: test adapter
- Production: Redis (if configured)

---

## Cache
**File:** `config/cache.yml`

**Caching Configuration:**
- Development: file_store or memory_store
- Test: null_store
- Production: redis_cache_store (if configured)

---

## Deployment

### Deploy Configuration
**File:** `config/deploy.yml`

Deployment configuration (likely for Kamal or similar).

---

## Boot Configuration

### Boot
**File:** `config/boot.rb`
- Sets up Bundler
- Requires bootsnap for faster boot times

### Environment
**File:** `config/environment.rb`
- Loads Rails application
- Initializes the application

---

## Environment Variables

**Required in Production:**
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Rails secret (auto-generated)
- `R2_ENDPOINT` - CloudFlare R2 endpoint
- `R2_ACCESS_KEY` - CloudFlare R2 access key
- `R2_SECRET_KEY` - CloudFlare R2 secret key
- `R2_BUCKET_NAME` - CloudFlare R2 bucket name
- Resend API key (for emails)

**Optional:**
- `RAILS_MAX_THREADS` - Thread pool size
- `WEB_CONCURRENCY` - Number of Puma workers
- `RAILS_LOG_LEVEL` - Logging verbosity
- `RAILS_SERVE_STATIC_FILES` - Serve assets from Rails

---

## Configuration Best Practices

1. **Secrets Management:**
   - Never commit secrets to git
   - Use encrypted credentials or environment variables
   - Different secrets per environment

2. **Environment-Specific Config:**
   - Development: verbose logging, caching disabled
   - Test: fast, isolated
   - Production: optimized, secure

3. **Database:**
   - Connection pooling configured
   - Production uses DATABASE_URL
   - Schema managed by migrations

4. **Assets:**
   - Import maps for JavaScript (no build step)
   - Propshaft for CSS/images
   - CloudFlare R2 for uploaded files in production

5. **Background Jobs:**
   - SolidQueue (no external dependencies)
   - Database-backed queue
   - Recurring tasks support

6. **Email:**
   - Resend for transactional emails
   - Devise for authentication emails
   - Production SMTP configured

7. **Security:**
   - CSP headers
   - Parameter filtering
   - HTTPS in production
   - Secure session cookies
