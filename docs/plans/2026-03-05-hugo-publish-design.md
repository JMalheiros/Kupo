# Hugo Publish - Design

## Summary

When an article is published in KUPO (`publish_now!`), a background job clones the Hugo repo, generates a Hugo-formatted post with front matter, downloads attached images into the page bundle, commits, and pushes to main. GitHub Pages rebuilds automatically.

## Architecture

```
User clicks "Publish"
  -> publish_now! (existing flow)
  -> Enqueues HugoPublishJob (Solid Queue)
  -> Job clones Hugo repo via deploy key (SSH)
  -> HugoPostFormatter builds front matter + rewrites image URLs
  -> Downloads images from ActiveStorage into page bundle
  -> Creates content/posts/{slug}/index.md
  -> Commits and pushes to main
  -> GitHub Pages rebuilds
```

## Hugo Post Format

For an article with slug `my-article`, published on 2026-03-05, in categories "tech" and "rails":

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

## Backend Components

| Component | Responsibility |
|-----------|---------------|
| `HugoPublishJob` | Clones repo to temp dir, orchestrates formatting + commit + push, cleans up temp dir |
| `HugoPostFormatter` | Converts article to Hugo markdown: builds YAML front matter, rewrites image URLs to relative paths |
| `HugoGitClient` | Wraps git operations: clone via SSH deploy key, add, commit, push |

## Image Handling

1. Scan article body for `![...](/rails/active_storage/blobs/redirect/{signed_id}/filename.png)` patterns
2. For each match, find the corresponding `ActiveStorage::Blob` by signed ID
3. Download the blob to `content/posts/{slug}/filename.png`
4. Rewrite the markdown reference to `![...](filename.png)`

## Configuration

```env
HUGO_REPO_SSH_URL=git@github.com:user/blog.git   # Hugo repo SSH URL
HUGO_DEPLOY_KEY_PATH=/path/to/deploy_key          # Path to SSH private key
```

The deploy key (with write access) is added to the Hugo repo's Settings > Deploy Keys.

## Error Handling

- **Clone/push failure:** Job retries (Solid Queue built-in retries), logs error
- **Image download failure:** Skip the image, keep original URL, log warning
- **Article has no body:** Skip publishing, log warning

## Scope

- **Publish only** -- no sync on update/unpublish
- **No PR workflow** -- direct push to main
- One-way: KUPO to Hugo. Hugo repo is never read back.

## Testing

- **`HugoPostFormatterTest`** -- verifies front matter generation, image URL rewriting, category mapping
- **`HugoGitClientTest`** -- stubbed git commands, verifies clone/commit/push sequence
- **`HugoPublishJobTest`** -- verifies it calls formatter and git client, handles errors gracefully
- **`PublishArticleJob` update** -- verify it enqueues `HugoPublishJob` after publishing
