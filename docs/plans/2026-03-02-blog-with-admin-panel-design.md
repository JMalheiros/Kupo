# MStation Blog with Admin Panel — Design Document

**Date**: 2026-03-02
**Status**: Approved

## Overview

MStation is a single-author blog with an admin panel. The public side displays published articles with category filtering. The admin side provides markdown editing with live preview, scheduled publishing, and category management. The entire app runs as a single-page application using Hotwire (Turbo + Stimulus) with a single layout and auth-guarded admin features.

## Data Model

### Article
- `title` (string, required)
- `slug` (string, unique, auto-generated from title)
- `body` (text, raw markdown)
- `status` (string, enum: `draft`, `scheduled`, `published`)
- `published_at` (datetime, nullable)
- `timestamps`

### Category
- `name` (string, required, unique)
- `slug` (string, unique, auto-generated)
- `timestamps`

### ArticleCategory (join table)
- `article_id` (foreign key)
- `category_id` (foreign key)
- Unique index on `[article_id, category_id]`

### User (Rails 8 auth generator)
- `email_address` (string)
- `password_digest` (string)
- Standard Rails 8 auth fields (sessions)

### ActiveStorage
- Articles have `has_many_attached :images` for inline image uploads in markdown content.

## Architecture

### Single Layout with Auth Guards

One layout for the entire app. Admin features (create, edit, delete, publish) are shown/hidden based on authentication status. Controllers use `before_action` auth guards for admin-only actions.

### Routes

**Public:**
- `GET /` — Article list (root), filterable by category
- `GET /articles/:slug` — Show article (modal when navigating within app, full page for direct links)

**Auth (Rails 8 generator):**
- `GET /sign_in` — Login form
- `POST /sessions` — Create session
- `DELETE /sessions/:id` — Logout

**Admin (auth-guarded):**
- `GET /articles/new` — New article form (modal)
- `POST /articles` — Create article
- `GET /articles/:slug/edit` — Edit article form (modal)
- `PATCH /articles/:slug` — Update article
- `DELETE /articles/:slug` — Delete article
- `POST /articles/:slug/publish` — Publish/schedule article
- `POST /articles/preview` — Markdown preview endpoint
- `GET /categories` — Category management
- `POST /categories` — Create category
- `DELETE /categories/:id` — Delete category

### Hotwire Navigation

- Root page loads article list
- Clicking an article opens it in a modal via Turbo Frame (`data-turbo-action="advance"` updates URL to `/articles/:slug`)
- Closing modal / pressing back returns to list, URL returns to `/`
- Direct links to `/articles/:slug` render a full page (so shared links work)
- Admin forms (new/edit) also open in modals
- Category filtering updates article list via Turbo Frames

## Markdown Editing & Rendering

### Server-Side Rendering
- **Gem**: `redcarpet` for markdown-to-HTML conversion
- **Syntax highlighting**: `rouge` gem integrated with redcarpet custom HTML renderer
- Features enabled: fenced code blocks, autolinks, tables, strikethrough

### Editor with Live Preview
- Split view: textarea on left, rendered preview on right
- Stimulus controller (`markdown-preview`) debounces input (~300ms) and sends markdown to `POST /articles/preview`
- Server renders HTML with the same redcarpet pipeline used for final display
- Preview pane updates via DOM replacement

### Inline Images
- File upload button in editor inserts markdown image tags at cursor position
- Images uploaded via ActiveStorage direct upload
- Stimulus controller (`image-upload`) handles upload flow and cursor insertion

## Scheduled Publishing

### States
- **Draft**: Not visible, still being written
- **Scheduled**: Has future `published_at`, not yet visible
- **Published**: Visible to visitors, `published_at` in the past or now

### Individual Scheduled Jobs
- When admin sets a future `published_at` and saves, a `PublishArticleJob` is enqueued via Solid Queue with `set(wait_until: article.published_at)`
- The job updates `status` from `scheduled` to `published` at the exact time
- If rescheduled, the old job is discarded (job checks current status) and a new job is enqueued
- "Publish now" sets `status = "published"` and `published_at = Time.current` immediately

### Public Queries
- Article list shows only `status: "published"` articles, ordered by `published_at DESC`

## UI & Component Structure

### Public Components
- `Views::Articles::Index` — Article card list with category filter tabs
- `Views::Articles::Show` — Full article (rendered markdown), wrapped in modal
- `Views::Articles::Card` — Card for list (title, excerpt, date, categories)
- `Views::Categories::Filter` — Category tabs/pills for filtering
- `Components::Modal` — Reusable modal component

### Admin Components (under `Admin` module)
- `Views::Admin::Articles::Index` — Article list with status badges, edit/delete controls
- `Views::Admin::Articles::Form` — Markdown editor with live preview, in modal
- `Views::Admin::Categories::Index` — Category management
- `Components::Admin::StatusBadge` — Draft/Scheduled/Published badge
- `Components::Admin::MarkdownPreview` — Split-pane editor with preview

### Styling
- All components use existing Tailwind design tokens (`primary`, `secondary`, `muted`, `accent`, etc.)
- RubyUI components for buttons, forms, badges, dialog/modal
- Dark mode supported via existing token system
- Responsive design for mobile reading

### Admin UX (when authenticated)
- Article cards show edit/delete buttons
- "New Article" button in header or above list
- Status badges on each card
- Category management link

## Testing Strategy

### Factories
- `article` with traits: `:draft`, `:scheduled`, `:published`
- `category`
- `user`

### Model Tests
- Validations, scopes (`published`, `scheduled`, `drafts`)
- Slug generation
- Status transitions
- Scheduled publishing logic

### Controller Integration Tests
- Auth guards (unauthenticated can't access admin actions)
- CRUD operations for articles and categories
- Publish/schedule flows
- Markdown preview endpoint

### Job Tests
- `PublishArticleJob` correctly publishes a scheduled article
- Job discards gracefully if article is no longer scheduled

### System Tests
- Create article with markdown, verify rendering
- Schedule article, verify it appears after publish time
- Category filtering
- Modal open/close behavior
