# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KUPO is a Ruby on Rails 8.1 application using Ruby 4.0.1. It follows the Rails 8 "Solid" stack — SQLite3 for all databases, Solid Cache, Solid Queue, and Solid Cable replacing Redis entirely. Frontend is a single page application that uses Hotwire (Turbo + Stimulus), Phlex, RubyUI and import maps (no Node.js/bundler). There is only the root route, that starts on the Articles index, and the whole application updates the HTML using Hotwire.

## Common Commands

### Development

```sh
bin/setup                # Install gems, prepare DB, start server
bin/setup --skip-server  # Setup without starting server
bin/dev                  # Start development server (Puma on port 3000)
```

### Testing (Minitest)

```sh
bin/rails test                              # Run all tests
bin/rails test test/models/user_test.rb     # Run a specific test file
bin/rails test test/models/user_test.rb:25  # Run test at specific line
bin/rails test:system                       # Run system tests
```

Also uses Shoulda-Matchers, Shoulda-Context, Simplecov and Factory Bot Rails.

Tests run in parallel across available CPU cores.

### Linting & Security

```sh
bin/rubocop              # Run RuboCop (rubocop-rails-omakase style)
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit        # Gem CVE audit
bin/importmap audit      # JS dependency audit
```

### Full CI (runs all checks in sequence)

```sh
bin/ci
```

CI steps: setup → rubocop → bundler-audit → importmap audit → brakeman → rspec → seed test.

## Architecture

- **Database**: SQLite3 everywhere. Production uses four separate databases (primary, cache, queue, cable) stored in `storage/`.
- **Authentication**: Uses Rails 8 built-in generator. Every controller inherits `Authentication` through `ApplicationController`. Used to access the admin panel.
- **Background Jobs**: Solid Queue runs inside the Puma process (`SOLID_QUEUE_IN_PUMA`), no separate worker process needed.
- **Asset Pipeline**: Propshaft (not Sprockets).
- **JavaScript**: Import maps via `config/importmap.rb`. Stimulus controllers in `app/javascript/controllers/`.
- **Deployment**: Kamal (Docker-based), configured in `config/deploy.yml`.
- **CI**: GitHub Actions (`.github/workflows/ci.yml`), mirrors `bin/ci` steps.
- **FileStorage**: Uses ActiveStorage and local disk on development. Uses Amazon S3 on production.
- **FrontEnd**: Use RubyUI as much as possible.

## Pre-Commit Checklist

Before commiting any code, verify:

  1. `bundle exec rails test` - all test pass, zero failures
  2. `bundle exec rubocop` - zero offenses
  3. `bundle exec brakeman --no-pager --quiet` - no new warnings
  4. `bundle exec bundler-audit check` - no vulnerable gems
  5. New models have factory + model tests
  6. New controllers have integration tests covering auth, happy path, and error cases
  7. Views use existing Tailwind tokens (`primary`, `dark-bg`, etc.) - not raw colors
  8. Sensitive data uses `encrypts` or ENV vars - never hardcoded
