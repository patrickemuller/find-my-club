# Find My Club - Claude Code Context

## Application Overview

**Find My Club** is a Rails 8 application for discovering and managing sports clubs. Users can create clubs, manage memberships, organize events, and coordinate participation.

**Tech Stack:** Rails 8, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS 4, Devise

## Token Usage Optimization Guide

### 1. **Use Micro Context Files First**
Before exploring the codebase, **ALWAYS** read the relevant micro context files from `.claude/structure/`:

- **Controllers** → `.claude/structure/controllers.md` - All endpoints and actions
- **Models** → `.claude/structure/models.md` - Database models, associations, validations
- **Views** → `.claude/structure/views.md` - Templates and partials
- **JavaScript** → `.claude/structure/javascripts.md` - Stimulus controllers and Hotwire
- **Styles** → `.claude/structure/styles.md` - Tailwind CSS and dark mode
- **Database** → `.claude/structure/database.md` - Schema, migrations, relationships
- **Tests** → `.claude/structure/tests.md` - RSpec specs and factories
- **Config** → `.claude/structure/config.md` - Environment and initializers
- **Lib** → `.claude/structure/lib.md` - Helpers and custom utilities

### 2. **Read Only What You Need**
- Don't read entire files unless necessary
- Use `Grep` or `Glob` to find specific code patterns
- Consult structure files to identify the correct files before reading
- Use line offsets and limits when reading large files

### 3. **Leverage the Task Tool**
For complex exploration or research tasks, use the Task tool with `subagent_type=Explore` instead of running multiple search commands directly.

### 4. **Use Commands for Workflows**
- `/plan [description]` - Plan implementation (reads structure files, creates task file)
- `/implement [task_file]` - Execute planned tasks (updates structure files after)

## Core Domain Models

```
User (Devise auth)
   owns → Club (1:many)
   joins → Club via Membership (many:many)
   registers → Event via EventRegistration (many:many)

Club (with slug, categories, levels)
   has → Event (1:many)
   has → Membership (1:many)

Event (scheduled activities)
   has → EventRegistration (1:many)
```

**Key Features:**
- Club creation with public/private visibility
- Membership approval workflow (pending → active)
- Event registration with waitlists
- Calendar views for events
- Rich text descriptions (ActionText/Trix)

## Architecture Patterns

**Backend:**
- Rails MVC with concerns
- FriendlyId for slugs (clubs, events)
- ActiveStorage + CloudFlare R2 (production)
- SolidQueue for background jobs
- Resend for transactional emails

**Frontend:**
- Hotwire (Turbo Drive, Frames, Streams)
- Stimulus controllers for interactivity
- Tailwind CSS 4 (utility-first)
- Dark mode with `[data-theme="dark"]`
- Mobile-first responsive design

**Testing:**
- RSpec Rails with FactoryBot
- Capybara for system tests (headless Chrome)
- SimpleCov for coverage (when enabled)

## Key Conventions

**Code Style:**
- Reuse existing code patterns
- Use Rails/Hotwire standards over external gems
- Mobile-first design approach
- Simple solutions over complex abstractions
- No performance optimizations without necessity

**Development:**
- Plan tasks in `.claude/tasks/[branch-name].md`
- Update `.claude/structure/` files after changes
- Run tests with `COVERAGE=false bundle exec rspec`
- No time estimates in plans

## Quick Reference

**Important Paths:**
- Controllers: `app/controllers/`
- Models: `app/models/`
- Views: `app/views/`
- JavaScript: `app/javascript/controllers/`
- Tests: `spec/`
- Routes: `config/routes.rb`

**Common Commands:**
```bash
# Tests
bundle exec rspec
COVERAGE=false bundle exec rspec spec/system/

# Database
rails db:migrate
rails db:seed

# Server
bin/dev  # Starts Rails + Tailwind watch
```

## Custom Commands

### `/plan [description]`
**Purpose:** Plan feature implementation

**Process:**
1. Reads necessary `.claude/structure/` files
2. Plans implementation steps
3. Creates/updates task file in `.claude/tasks/[branch-name].md`

**Guidelines:**
- Reuse existing code patterns
- Simple, minimal changes
- Mobile-first design
- No time/line estimates
- Include max 3 edge cases

### `/implement [task_file]`
**Purpose:** Execute planned implementation

**Process:**
1. Implements feature from task file
2. Updates documentation in `.claude/structure/`

**Guidelines:**
- Strictly follow plan
- Don't change unplanned files
- Don't inject edge cases

## Routing Structure

```
GET    /                          → pages#home
       /clubs                     → clubs#index (public clubs)
GET    /clubs/:id                 → clubs#show
POST   /clubs/:id/memberships     → memberships#create (join)
GET    /clubs/:id/events          → events#index
POST   /clubs/:id/events          → events#create
       /my-clubs                  → clubs#my_clubs (owned/joined)
       /users/:id                 → users/profiles#show
```

Full routing in `.claude/structure/controllers.md`

## Authorization

- Club owners can manage clubs, events, memberships
- Users can join public clubs
- Event registration requires active membership
- Owner auto-participates in events (no registration needed)

## Environment Variables (Production)

```
DATABASE_URL           # PostgreSQL
SECRET_KEY_BASE        # Rails secret
R2_ENDPOINT           # CloudFlare R2
R2_ACCESS_KEY         # CloudFlare R2
R2_SECRET_KEY         # CloudFlare R2
R2_BUCKET_NAME        # CloudFlare R2 (default: find-my-club-production)
RESEND_API_KEY        # Email service
```

## Working with Claude Code

### Before Starting Any Task

1. **Identify the domain** (clubs, events, memberships, users)
2. **Read relevant structure file(s)** from `.claude/structure/`
3. **Search for specific code** using Grep/Glob if needed
4. **Read actual files** only after narrowing down location

### During Implementation

1. **Use TodoWrite** for multi-step tasks
2. **Ask questions** with AskUserQuestion when unclear
3. **Update structure files** after making changes
4. **Run tests** to verify changes

### After Implementation

1. **Update `.claude/structure/` files** to reflect changes
2. **Run full test suite** if significant changes
3. **Update task file** with completion notes (if applicable)

## Additional Resources

- **Application config:** `.claude/structure/config.md`
- **Testing guide:** `.claude/structure/tests.md`
- **Full schema:** `.claude/structure/database.md` or `db/schema.rb`
- **Task files:** `.claude/tasks/*.md`

---

**Remember:** Always read structure files BEFORE exploring code directly. This minimizes token usage and provides faster context acquisition.
