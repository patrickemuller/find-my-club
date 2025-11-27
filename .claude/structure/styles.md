# Styles

This document provides a breakdown of all styling in the Find My Club application.

## Overview

The application uses **Tailwind CSS 4** as its primary styling framework, with custom CSS for specific components.

---

## Styling Architecture

### Tailwind CSS

**Main File:** `app/assets/tailwind/application.css`

```css
@import "tailwindcss";

@tailwind base;
@tailwind components;
@tailwind utilities;
@tailwind elements;

@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
```

**Features:**
- Tailwind CSS 4.0 (latest version)
- Custom dark mode variant using `[data-theme="dark"]` attribute
- Utility-first CSS approach
- JIT (Just-In-Time) compilation
- No separate configuration file (uses defaults)

**Build Process:**
- Compiled by Tailwind CLI
- Output: `app/assets/builds/tailwind.css`
- Watched in development mode
- Optimized for production (purged unused styles)

---

## CSS Files

### Application CSS
**File:** `app/assets/stylesheets/application.css`

Empty manifest file for additional custom styles. Uses Propshaft asset pipeline.

### ActionText CSS
**File:** `app/assets/stylesheets/actiontext.css`

Comprehensive styling for Trix rich text editor and ActionText content.

**Key Sections:**

1. **Trix Editor Styles**
   - Editor border, padding, min-height
   - Focus states with orange accent color
   - Dark mode support

2. **Trix Toolbar**
   - Button groups and layouts
   - Icon buttons with SVG backgrounds
   - Responsive design for mobile
   - Hover and active states

3. **Toolbar Icons**
   All editor icons are embedded as SVG data URIs:
   - Bold, Italic, Strikethrough
   - Links, Quotes, Code
   - Headings
   - Bullet/Number lists
   - Undo/Redo
   - Increase/Decrease nesting
   - File attachments

4. **Editor Dialogs**
   - Link dialog with URL input
   - Modal overlay styles
   - Form inputs for dialogs

5. **Attachment Display**
   - File attachments
   - Image attachments
   - Attachment captions
   - Progress indicators
   - Attachment toolbars

6. **Content Display (.trix-content)**
   - Headings, paragraphs
   - Lists (ordered/unordered)
   - Blockquotes
   - Code blocks
   - Image galleries
   - Line height and spacing

7. **Dark Mode Support**
   - Dark background colors (grays)
   - Light text colors
   - Adjusted border colors
   - Dark toolbar with proper contrast
   - Dark code blocks and blockquotes
   - Active states in dark mode

**Color Scheme:**
- Light mode: White/gray backgrounds, black text
- Dark mode: Gray-800/900 backgrounds, white/gray-100 text
- Accent: Orange (#ea580c / rgb(234 88 12))
- Focus ring: Orange

---

## Design System

### Colors

**Primary Palette:**
- Orange: `rgb(234 88 12)` - Primary brand color, CTAs, focus states
- Gray scale: Tailwind's default gray palette
- Dark theme: Gray-800/900 backgrounds

**Semantic Colors:**
- Success: Green (form success, confirmations)
- Error: Red (validation errors, warnings)
- Info: Blue (informational messages)

### Typography

**Font Stack:**
- System fonts (Tailwind default)
- Monospace for code blocks

**Font Sizes:**
- Tailwind's default scale (text-xs to text-9xl)
- Custom sizing for Trix editor elements

**Line Heights:**
- Default: 1.5 for body text
- Tighter for headings

### Spacing

- Tailwind's default spacing scale
- Consistent padding/margin across components

### Border Radius

- Tailwind defaults (sm, md, lg, full)
- Rounded corners for cards, buttons, inputs

---

## Component Styling Patterns

### Cards
- White background (light mode)
- Gray-800/900 background (dark mode)
- Subtle shadows
- Rounded corners
- Hover states

### Buttons
- Orange primary buttons
- Gray secondary buttons
- Hover and active states
- Focus rings for accessibility
- Disabled states

### Forms
- Consistent input styling
- Orange focus rings
- Dark mode input backgrounds
- Error state styling
- Label positioning

### Navigation
- Header with gradient or solid background
- Dropdown menus with smooth transitions
- Mobile menu with overlay
- Active link highlighting

### Tables
- Striped rows
- Hover states
- Responsive scrolling
- Dark mode colors

### Modals
- Backdrop overlay
- Centered content
- Close button
- Smooth animations

---

## Dark Mode Implementation

**Strategy:**
- Attribute-based: `[data-theme="dark"]`
- JavaScript toggle (theme_toggle_controller.js)
- Persisted to localStorage
- Respects system preferences

**Custom Variant:**
```css
@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
```

**Usage in HTML:**
```html
<html data-theme="dark">
```

**Coverage:**
- All UI components
- Trix editor and toolbar
- Forms and inputs
- Navigation
- Cards and modals
- Code blocks and content

---

## Responsive Design

**Breakpoints (Tailwind defaults):**
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

**Mobile-First Approach:**
- Base styles for mobile
- Progressive enhancement for larger screens
- Mobile menu for navigation
- Responsive grids and layouts
- Touch-friendly interactions

**Specific Responsive Features:**
- Calendar grid adapts to screen size
- Navigation collapses to hamburger menu
- Cards stack on mobile
- Tables scroll horizontally
- Forms adapt layout

---

## Custom CSS Components

### Calendar
- Grid layout (7 columns)
- Day cells with hover states
- Event badges
- Today highlighting
- Month navigation

### Breadcrumbs
- Horizontal navigation
- Separator icons
- Truncation on mobile

### Flash Messages
- Toast-style notifications
- Auto-dismiss
- Color-coded by type
- Slide-in animation

### Tooltips
- Positioned overlays
- Dark background
- Pointer/arrow
- Hover/focus triggers

### Carousel
- Image slider
- Navigation dots
- Swipe gestures
- Auto-play option

---

## Icons and Images

**Icon Strategy:**
- SVG icons embedded in CSS (Trix toolbar)
- Icon files in `app/assets/icons/`
- Social media icons: Strava, TrailForks, Outside.com, Athlinks

**Images:**
- `app/assets/images/` directory
- ActiveStorage for user uploads
- Responsive images with max-width
- CloudFlare R2 for production storage

---

## Performance Optimizations

1. **Tailwind JIT:**
   - Only generates used classes
   - Fast build times
   - Small CSS bundle

2. **Asset Pipeline (Propshaft):**
   - No preprocessing overhead
   - Fast asset serving
   - Content-addressable caching

3. **CSS Purging:**
   - Unused Tailwind classes removed in production
   - Minimal CSS payload

4. **SVG Data URIs:**
   - Inline SVGs reduce HTTP requests
   - No external icon files needed

---

## Accessibility

**Focus States:**
- Visible focus rings (orange)
- Consistent across all interactive elements
- High contrast in dark mode

**Color Contrast:**
- WCAG AA compliant
- Tested for light and dark modes
- Sufficient contrast ratios

**Typography:**
- Readable font sizes
- Adequate line height
- No text smaller than 12px (except metadata)

---

## File Structure

```
app/assets/
├── builds/
│   └── tailwind.css          # Compiled Tailwind (generated)
├── stylesheets/
│   ├── application.css        # Main CSS manifest
│   └── actiontext.css         # Trix/ActionText styles
├── tailwind/
│   └── application.css        # Tailwind source
├── icons/
│   └── *.svg                  # Icon files
└── images/
    └── *.png, *.svg, *.webp  # Images
```

---

## Styling Guidelines

1. **Use Tailwind utilities first**
   - Prefer utility classes over custom CSS
   - Only write custom CSS for complex components

2. **Follow naming conventions**
   - BEM for custom components if needed
   - Tailwind's naming for utilities

3. **Dark mode consideration**
   - Always test both light and dark modes
   - Use Tailwind's dark: variant

4. **Responsive design**
   - Mobile-first approach
   - Test on all breakpoints

5. **Consistency**
   - Use design tokens (colors, spacing)
   - Follow established patterns
   - Maintain visual hierarchy
