# Rename MStation → KUPO — Design Document

**Date**: 2026-03-04
**Status**: Approved

## Overview

Rename the project from "MStation" to "KUPO" across all files.

## Naming Convention

| Context | Old | New |
|---------|-----|-----|
| Display name (title, header, PWA) | MStation | KUPO |
| Ruby module | `MStation` | `Kupo` |
| Snake_case (configs, Docker) | `m_station` | `kupo` |
| Email domain | `mstation.com` | `kupo.com` |

## Files Changed

1. `config/application.rb` — module name
2. `app/views/layouts/application.html.erb` — title, meta, header
3. `app/views/pwa/manifest.json.erb` — PWA name/description
4. `config/deploy.yml` — service, image, volume names
5. `Dockerfile` — comment references
6. `db/seeds.rb` — admin email
7. `test/factories/users.rb` — factory email
8. `CLAUDE.md` — project overview
9. `docs/plans/2026-03-02-blog-implementation-plan.md` — references
10. `docs/plans/2026-03-02-blog-with-admin-panel-design.md` — references

## Not Changed

- Directory name on disk (`m_station/`) — external to repo
- Database files in `storage/` — runtime artifacts
