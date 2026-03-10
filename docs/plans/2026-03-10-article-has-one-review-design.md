# Article has_one Review

**Date:** 2026-03-10
**Status:** Approved

## Summary

Refactor the article review system from `has_many :article_reviews` to `has_one :article_review`. When a user requests a new review, the existing review and its suggestions are replaced entirely.

## Changes

### Model: Article

Change `has_many :article_reviews, dependent: :destroy` to `has_one :article_review, dependent: :destroy`.

### Model: ArticleReview

No changes to the model itself.

### Controller: Articles::ReviewsController#create

Replace "always create new" with find-or-reset:

1. `find_or_initialize_by` on `article.article_review`
2. If review already exists: destroy existing suggestions, reset `content_status` and `seo_status` to `"pending"`
3. Save the review
4. Enqueue `ContentReviewJob` and `SeoReviewJob`

### Jobs and Service

No changes. They receive a review object and create suggestions on it.

### Component: Admin::Reviews

Simplify the review lookup from `@article.article_reviews.order(created_at: :desc).first` to `@article.article_review`.

### Migration

- Add unique index on `article_reviews.article_id` to enforce the constraint at the DB level
- Data migration: for any article with multiple reviews, keep the latest and delete the rest

### Tests

- Update Article model test: `has_one` instead of `has_many`
- Update ReviewsController test: verify re-review replaces suggestions
- Update ArticleReview model test: no structural changes expected
