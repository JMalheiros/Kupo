# Article Plan — Design

## Goal

Add an optional `plan` text field to articles, shown in a "Plan" tab alongside Edit and Review, where users can draft a rough outline of the article content and structure in markdown.

## Data Model

Single `plan` text column on the `articles` table. Nullable, no validation — the plan is entirely optional.

## UI

- New "Plan" tab in the tabbed content area (Edit | Plan | Review for persisted articles, Edit | Plan for new articles)
- Plan tab contains a markdown editor with Write/Preview tabs (reuses the `MarkdownPreview` component pattern)
- Plan content submitted as `article[plan]` via its own form (PATCH to existing article endpoint)
- No new controller or route — just permit the `plan` param

## Tech Stack

- Migration: add `plan` text column to articles
- Controller: permit `plan` param in articles controller
- Component: `Components::Admin::Articles::ArticlePlan` with markdown textarea + preview
- View: add Plan tab trigger and content in `Views::Admin::Articles::Form`
