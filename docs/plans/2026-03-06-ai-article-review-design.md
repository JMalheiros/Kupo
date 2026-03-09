# AI Article Review — Design

## Goal

Add an AI-powered review feature to the article edit form that analyzes articles across two parallel processes (Content Review and SEO/Metadata Review), presents individual suggestions the user can accept or reject, and applies accepted changes after showing a diff.

## Architecture

Single "Review" button in a new Review tab (alongside Write/Preview) triggers both review processes in parallel as Solid Queue jobs. Each job calls Gemini via the `langchain` gem, parses structured JSON responses into `ReviewSuggestion` records, and broadcasts results to the UI via Turbo Streams over Action Cable (Solid Cable).

## Data Model

### ArticleReview

| Field | Type | Notes |
|-------|------|-------|
| id | integer | PK |
| article_id | integer | FK, belongs_to Article |
| content_status | string | pending / completed / failed |
| seo_status | string | pending / completed / failed |
| created_at | datetime | |

### ReviewSuggestion

| Field | Type | Notes |
|-------|------|-------|
| id | integer | PK |
| article_review_id | integer | FK, belongs_to ArticleReview |
| process | string | "content" or "seo" |
| category | string | grammar / clarity / tone / structure / title / seo / summary / tags |
| original_text | text | The text being flagged (nullable for new additions like tags) |
| suggested_text | text | The suggested replacement or addition |
| explanation | text | Why this change is suggested |
| status | string | pending / accepted / rejected (default: pending) |

## Review Processes

### Content Review (ContentReviewJob)

Analyzes article body for:
- **Grammar** — spelling, punctuation, syntax errors
- **Clarity** — ambiguous phrasing, overly complex sentences
- **Tone** — consistency, appropriate for target audience
- **Structure** — paragraph organization, heading hierarchy, flow

### SEO & Metadata Review (SeoReviewJob)

Analyzes article title + body for:
- **Title** — improvements for engagement and searchability
- **SEO** — meta description suggestions, keyword usage
- **Summary** — article summary/excerpt suggestions
- **Tags** — suggested category/tag additions based on content

## Job Flow

1. User clicks "Review Article" in the Review tab
2. Controller creates an `ArticleReview` record (both statuses: pending)
3. Enqueues `ContentReviewJob` and `SeoReviewJob` in parallel
4. Each job:
   - Calls Gemini via Langchain with a structured prompt
   - Parses JSON response into `ReviewSuggestion` records
   - Updates the corresponding status on `ArticleReview` to completed/failed
   - Broadcasts suggestions via `Turbo::StreamsChannel.broadcast_append_to` targeting the review tab
5. UI shows suggestions as they arrive (content and SEO sections load independently)

## UI Flow

### Review Tab

- "Review Article" button (disabled while a review is in progress)
- Two collapsible sections: "Content Review" and "SEO & Metadata Review"
- Each section shows a loading spinner until its job completes
- When complete, displays a list of suggestions

### Suggestion Card

- Category badge (grammar, clarity, title, etc.)
- Original text (highlighted) and suggested replacement
- Explanation of why
- Accept / Reject buttons

### Accept Flow

1. User clicks Accept
2. Shows a diff view (original vs suggested) with Confirm / Cancel
3. On Confirm: applies the change to the article body/title, marks suggestion as accepted
4. Article form updates in place (Turbo Stream or Stimulus)

### Reject Flow

1. User clicks Reject
2. Marks suggestion as rejected, visually dims/removes it

## Tech Stack

- **LLM**: Google Gemini via `langchain` gem
- **Jobs**: Solid Queue (ContentReviewJob, SeoReviewJob)
- **Real-time**: Solid Cable (Action Cable) with Turbo Streams
- **UI**: Phlex views, RubyUI components, Stimulus controllers
- **Diff**: Simple inline diff rendered server-side

## Error Handling

- If a job fails (LLM timeout, bad response), set process status to "failed" and broadcast an error message to the section
- User can retry individual processes
- Malformed LLM responses are logged and treated as failures
