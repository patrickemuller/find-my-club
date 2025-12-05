# Controllers

This document provides a breakdown of all controllers in the Find My Club application.

## Application Controller
**File:** `app/controllers/application_controller.rb`
- Base controller that all other controllers inherit from
- Contains shared authentication and authorization logic

## Club Invitations Controller
**File:** `app/controllers/club_invitations_controller.rb`
- Manages club invitation operations
- **Actions:**
  - `new` - Show invitation modal (owner only)
  - `create` - Send invitations to email addresses (owner only)
  - `resend` - Re-send invitation email (owner only)
  - `destroy` - Delete an invitation (owner only)
  - `accept` - Accept invitation (requires email match with logged-in user)
  - `reject` - Reject invitation
- **Security:** Email validation ensures logged-in user's email matches invitation email (case-insensitive)

## Pages Controller
**File:** `app/controllers/pages_controller.rb`
- Handles static pages
- **Actions:**
  - `home` - Landing page/root path

## Clubs Controller
**File:** `app/controllers/clubs_controller.rb`
- Manages club CRUD operations
- **Actions:**
  - `index` - List all public clubs (with filtering by category, level, search)
  - `show` - Display single club details
  - `new` - Show form to create new club
  - `create` - Create new club
  - `edit` - Show form to edit club
  - `update` - Update club details
  - `destroy` - Delete club
  - `my_clubs` - List clubs owned by or joined by current user
  - `members` - Show club members list (owner only)
  - `enable` - Enable a disabled club (owner only)
  - `disable` - Disable a club (owner only)

## Memberships Controller
**File:** `app/controllers/memberships_controller.rb`
- Manages club membership operations
- **Actions:**
  - `create` - Join a club (creates pending membership)
  - `destroy` - Leave a club
  - `approve` - Approve pending membership (owner only)
  - `enable` - Re-enable disabled membership (owner only)
  - `disable` - Disable active membership (owner only)

## Events Controller
**File:** `app/controllers/events_controller.rb`
- Manages event CRUD operations within clubs
- **Actions:**
  - `index` - List all events for a club
  - `show` - Display single event details
  - `new` - Show form to create new event
  - `create` - Create new event
  - `edit` - Show form to edit event
  - `update` - Update event details
  - `destroy` - Delete event
  - `registrations` - View all registrations for an event (owner only)

## Event Registrations Controller
**File:** `app/controllers/event_registrations_controller.rb`
- Manages event registration operations
- **Actions:**
  - `create` - Register for an event
  - `destroy` - Cancel event registration
  - `approve` - Approve waitlist registration (owner only)

## Places Controller
**File:** `app/controllers/places_controller.rb`
- Handles location autocomplete functionality
- **Actions:**
  - `autocomplete` - Returns location suggestions (API endpoint)

## Webhooks Controllers

### Stripe Webhooks Controller
**File:** `app/controllers/webhooks/stripe_controller.rb`
- Handles Stripe webhook events
- **Actions:**
  - `create` - Receives and processes Stripe webhook events
- **Handled Events:**
  - `customer.subscription.updated` - Subscription status changed
  - `customer.subscription.deleted` - Subscription cancelled
  - `invoice.paid` - Invoice successfully paid
  - `invoice.payment_failed` - Invoice payment failed
  - `invoice.updated` - Invoice updated
- **Security:** Verifies Stripe webhook signatures

## Users Controllers

### Profiles Controller
**File:** `app/controllers/users/profiles_controller.rb`
- Manages user profile display and updates
- **Actions:**
  - `show` - Display user profile
  - `edit` - Show form to edit profile
  - `update` - Update user profile

### Subscriptions Controller
**File:** `app/controllers/users/subscriptions_controller.rb`
- Manages user subscriptions display
- **Actions:**
  - `index` - Display all paid club memberships with their pricing

### Registrations Controller
**File:** `app/controllers/users/registrations_controller.rb`
- Extends Devise registration controller
- Handles custom user registration logic
- Inherits from `Devise::RegistrationsController`

## Routing Structure

The application uses nested routing:
- `/clubs/:id/memberships` - Membership management
- `/clubs/:club_id/events/:id` - Events within clubs
- `/clubs/:club_id/events/:event_id/event_registrations` - Event registrations
- `/my-clubs` - User's clubs (owned or joined)
- `/users/:id` - User profiles
- `/users/subscriptions` - User subscriptions
- `/webhooks/stripe` - Stripe webhook endpoint (POST)

## Authorization Notes

Controllers implement authorization checks:
- Club owners can manage their clubs, events, and memberships
- Users can only join public clubs or clubs they're invited to
- Event registration requires active club membership
- Profile updates restricted to profile owner