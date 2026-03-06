# Hugo Publish - Design

## Summary

When an article is published in KUPO, a background job clones the Hugo repo, generates a Hugo-formatted post with front matter, downloads attached images into the page bundle, commits, and pushes to main. GitHub Pages rebuilds automatically. The user is notified via a toast when publishing completes or fails.

## Architecture

```
User clicks "Publish Now"
  -> publish_now! sets status to "publishing"
  -> Enqueues PublishArticleJob
  -> Job: HugoPostFormatter builds front matter + rewrites image URLs
  -> Job: HugoGitClient clones repo, writes page bundle, pushes to main
  -> Job: Sets status to "published"
  -> Job: Broadcasts Turbo Stream toast notification to user
  -> GitHub Pages rebuilds automatically

Scheduled articles:
  -> schedule! enqueues PublishArticleJob at scheduled time
  -> PublishArticleJob sets status to "publishing", then follows same flow
```

## Status Flow

```
draft -> publishing -> published
                    -> draft (on failure)

scheduled -> publishing -> published
                        -> draft (on failure)
```

Valid statuses: `draft`, `scheduled`, `publishing`, `published`.

The article card badge shows `publishing` with an animated pulse.

On failure, status reverts to `draft` and a toast shows the error.

## Backend Components

| Component | Responsibility |
|-----------|---------------|
| `Article#publish_now!` | Sets status to `"publishing"`, enqueues `PublishArticleJob` |
| `PublishArticleJob` | Calls formatter + git client, sets final status, broadcasts toast |
| `HugoPostFormatter` | Converts article to Hugo markdown: YAML front matter, image URL rewriting to relative paths |
| `HugoGitClient` | Wraps git operations: clone via SSH deploy key, add, commit, push |

## Hugo Post Format

For an article with slug `my-article`:

```
content/posts/my-article/
  index.md
  photo.png
  diagram.jpg
```

`index.md`:
```markdown
---
title: "My Article"
date: 2026-03-05T14:30:00-03:00
categories: ["tech", "rails"]
draft: false
---

Article body with ![photo](photo.png) rewritten to relative paths...
```

## Image Handling

1. Scan article body for `![...](/rails/active_storage/blobs/redirect/{signed_id}/filename.png)` patterns
2. For each match, find the corresponding `ActiveStorage::Blob` by signed ID
3. Download the blob to `content/posts/{slug}/filename.png`
4. Rewrite the markdown reference to `![...](filename.png)`

## Notification (Turbo Stream Broadcast)

- Layout includes `turbo_stream_from current_user` to subscribe to user-specific stream
- A `#notifications` container is added to the layout for toast placement
- `PublishArticleJob` broadcasts a Turbo Stream `append` to the user's stream
- Toast is a styled div (success or destructive variant) that auto-dismisses after 5 seconds via a Stimulus controller
- Shows "Article '{title}' published successfully" or "Failed to publish '{title}'"

## Configuration

```env
HUGO_REPO_SSH_URL=git@github.com:user/blog.git   # Hugo repo SSH URL
HUGO_DEPLOY_KEY_PATH=/path/to/deploy_key          # Path to SSH private key
```

If either is missing, the job skips the Hugo push and sets status to `"published"` directly.

## Error Handling

- **Clone/push failure:** Status reverts to `"draft"`, toast shows error
- **Image download failure:** Skip the image, keep original URL, log warning
- **Article has no body:** Skip publishing, log warning

## Scope

- Publish only -- no sync on update/unpublish
- No PR workflow -- direct push to main
- One-way: KUPO to Hugo. Hugo repo is never read back.

## Testing

- **`HugoPostFormatterTest`** -- front matter generation, image URL rewriting, category mapping
- **`HugoGitClientTest`** -- stubbed git commands, verifies clone/commit/push sequence
- **`PublishArticleJobTest`** -- updated to verify Hugo publish flow, status transitions, toast broadcast
- **Integration test** -- verify `publish_now!` sets `"publishing"` and enqueues job
