# Personal Notebook Transformation Design

## Goal

Transform the KUPO blog into a personal notebook accessible only via admin login. Remove all unauthenticated views, merge admin and public views, add article preview and markdown export.

## Authentication Changes

- Remove `allow_unauthenticated_access` from `ArticlesController#index` and `#show`.
- Keep it only on `SessionsController#new`/`#create` and `PasswordsController`.
- Unauthenticated users get redirected to login.

## View Consolidation

- Remove public views: `Views::Articles::Index`, `Views::Articles::Show`, `Views::Articles::Card`, `Views::Categories::Filter`.
- Promote admin views as the main views — the admin article index (with status filters, status badges) becomes the root view.
- Update `ArticlesQuery` to always show all articles (no more public/authenticated split).

## Preview Route

- `GET /articles/:slug/preview` — renders the article as a read-only formatted view (authenticated).
- Provides a clean "final document" view separate from the edit form.

## Markdown Export

- `GET /articles/:slug/export` — downloads the article as a `.md` file.
- Format: title as `# heading`, followed by the body content.
- Download button on the preview page.
- Content-Disposition header triggers browser download as `<slug>.md`.

## Routes (all authenticated except login/password)

```
GET    /                        → articles#index (admin index with status filters)
GET    /articles/new            → articles#new
POST   /articles                → articles#create
GET    /articles/:slug/edit     → articles#edit
PATCH  /articles/:slug          → articles#update
DELETE /articles/:slug          → articles#destroy
POST   /articles/:slug/publish  → articles#publish
GET    /articles/:slug/preview  → articles#preview (read-only rendered view)
GET    /articles/:slug/export   → articles#export (markdown download)
POST   /articles/preview        → articles#markdown_preview (live markdown preview in editor)
```

## Files to Delete

- `app/views/articles/index.rb` (public index)
- `app/views/articles/show.rb` (public show)
- `app/views/articles/card.rb` (public card component)
- `app/views/categories/filter.rb` (public category filter)
- Related system tests for public browsing
