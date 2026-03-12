# KUPO

KUPO is an AI-powered article management system built with Rails 8.1. Write, review, and publish articles to a Hugo static site — all from a single-page admin interface.

It uses the Rails "Solid" stack (SQLite3, Solid Cache, Solid Queue, Solid Cable) with Hotwire, Phlex, and RubyUI on the frontend. AI-powered features include article plan generation, content review, and SEO review via configurable LLM providers (Gemini, OpenAI, Anthropic).

## Setup

```sh
bin/setup               # Install gems, prepare DB, and start the server
bin/setup --skip-server  # Setup without starting the server
```

## Commands

```sh
bin/dev                  # Start development server (port 3000)
bin/dev -b 0.0.0.0       # Start bound to all interfaces
bin/rails test           # Run all tests
bin/rubocop              # Lint with RuboCop
bin/ci                   # Run full CI pipeline (lint, audit, security, tests)
```

## Encryption

Active Record encryption is pre-configured with development defaults, so **no extra setup is needed** for local development. The initializer at `config/initializers/active_record_encryption.rb` falls back to hardcoded keys when the environment variables are not set.

In production, you must set the following environment variables with real keys:

```sh
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

Generate production keys with:

```sh
bin/rails db:encryption:init
```

## Hugo Integration

KUPO publishes articles to a Hugo site by pushing markdown page bundles to a git repository. When you publish an article, a background job clones the Hugo repo, writes the post to `content/posts/<slug>/index.md` with YAML front matter, copies attached images, and pushes the commit.

### Setup

1. **Create a deploy key** for your Hugo repository:

   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/kupo_deploy_key -N ""
   ```

2. **Add the public key** (`~/.ssh/kupo_deploy_key.pub`) to your Hugo repository as a deploy key with write access.

3. **Set the environment variables**:

   ```sh
   HUGO_REPO_SSH_URL=git@github.com:your-user/your-hugo-site.git
   HUGO_DEPLOY_KEY_PATH=/path/to/kupo_deploy_key
   ```

Without these variables, articles will transition to "published" status but won't be pushed to Hugo.

### Published post format

```
content/posts/my-article/
  index.md      # YAML front matter + markdown body
  photo.png     # Attached images (copied from ActiveStorage)
```

Front matter example:

```yaml
---
title: "My Article"
date: 2026-03-10T14:30:00-03:00
categories: ["Tech", "Rails"]
draft: false
---
```
