# Article has_one Review Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor from `Article has_many :article_reviews` to `has_one :article_review`, replacing suggestions on re-review.

**Architecture:** Change the association, add a unique index migration, update the controller to find-or-reset instead of always creating, simplify the component lookup.

**Tech Stack:** Rails 8.1, SQLite3, Minitest, FactoryBot, Shoulda

---

### Task 1: Migration — Add unique index on article_reviews.article_id

**Files:**
- Create: `db/migrate/TIMESTAMP_add_unique_index_to_article_reviews.rb`

**Step 1: Generate migration**

Run: `bin/rails generate migration AddUniqueIndexToArticleReviews`

**Step 2: Write migration**

```ruby
class AddUniqueIndexToArticleReviews < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate reviews, keeping the latest per article
    execute <<~SQL
      DELETE FROM article_reviews
      WHERE id NOT IN (
        SELECT MAX(id) FROM article_reviews GROUP BY article_id
      )
    SQL

    remove_index :article_reviews, :article_id
    add_index :article_reviews, :article_id, unique: true
  end

  def down
    remove_index :article_reviews, :article_id, unique: true
    add_index :article_reviews, :article_id
  end
end
```

**Step 3: Run migration**

Run: `bin/rails db:migrate`
Expected: Migration succeeds, `db/schema.rb` shows unique index.

**Step 4: Commit**

```
feat: add unique index on article_reviews.article_id
```

---

### Task 2: Model — Change Article association to has_one

**Files:**
- Modify: `app/models/article.rb:5`
- Modify: `test/models/article_review_test.rb`

**Step 1: Update the Article model**

In `app/models/article.rb`, change line 5:

```ruby
# Before
has_many :article_reviews, dependent: :destroy

# After
has_one :article_review, dependent: :destroy
```

**Step 2: Run existing tests to see what breaks**

Run: `bin/rails test`
Expected: Some tests fail due to association change.

**Step 3: Update ArticleReview model test**

The `should have_many` / `should belong_to` matchers in `test/models/article_review_test.rb` stay the same (ArticleReview still `belongs_to :article`). No changes needed there.

**Step 4: Run tests again**

Run: `bin/rails test test/models/article_review_test.rb`
Expected: PASS

**Step 5: Commit**

```
refactor: change Article from has_many to has_one article_review
```

---

### Task 3: Controller — Find-or-reset instead of always creating

**Files:**
- Modify: `app/controllers/articles/reviews_controller.rb:3-13`
- Modify: `test/controllers/articles/reviews_controller_test.rb`

**Step 1: Update the test for create action**

Replace the existing `POST #create` test context in `test/controllers/articles/reviews_controller_test.rb`:

```ruby
context "POST #create (authenticated)" do
  setup do
    @user = create(:user)
    sign_in(@user)
    @article = create(:article, :draft)
  end

  should "create an article review and enqueue both jobs" do
    assert_difference("ArticleReview.count", 1) do
      assert_enqueued_jobs 2 do
        post review_article_url(slug: @article.slug)
      end
    end

    assert_redirected_to edit_article_url(slug: @article.slug)
  end

  should "reuse existing review and replace suggestions on re-review" do
    review = create(:article_review, article: @article, content_status: "completed", seo_status: "completed")
    create(:review_suggestion, article_review: review)
    create(:review_suggestion, :seo, article_review: review)

    assert_no_difference("ArticleReview.count") do
      assert_enqueued_jobs 2 do
        post review_article_url(slug: @article.slug)
      end
    end

    review.reload
    assert_equal "pending", review.content_status
    assert_equal "pending", review.seo_status
    assert_equal 0, review.review_suggestions.count
    assert_redirected_to edit_article_url(slug: @article.slug)
  end
end
```

**Step 2: Run the new test to see it fail**

Run: `bin/rails test test/controllers/articles/reviews_controller_test.rb`
Expected: The "reuse existing review" test FAILS.

**Step 3: Update the controller**

Replace the `create` action in `app/controllers/articles/reviews_controller.rb`:

```ruby
def create
  @article = Article.find_by!(slug: params[:slug])
  review = @article.article_review

  if review
    review.review_suggestions.destroy_all
    review.update!(content_status: "pending", seo_status: "pending")
  else
    review = @article.create_article_review!
  end

  @categories = Category.all

  ContentReviewJob.perform_later(review, Current.user)
  SeoReviewJob.perform_later(review, Current.user)

  render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
end
```

**Step 4: Run all controller tests**

Run: `bin/rails test test/controllers/articles/reviews_controller_test.rb`
Expected: PASS

**Step 5: Commit**

```
refactor: controller find-or-resets review instead of always creating
```

---

### Task 4: Component — Simplify review lookup

**Files:**
- Modify: `app/components/admin/reviews.rb:6`

**Step 1: Update the component**

In `app/components/admin/reviews.rb`, change line 6:

```ruby
# Before
@latest_review = @article.article_reviews.order(created_at: :desc).first

# After
@latest_review = @article.article_review
```

**Step 2: Run all tests**

Run: `bin/rails test`
Expected: All tests PASS.

**Step 3: Commit**

```
refactor: simplify review lookup to has_one association
```

---

### Task 5: Full verification

**Step 1: Run full test suite**

Run: `bin/rails test`
Expected: All tests pass, zero failures.

**Step 2: Run linter**

Run: `bundle exec rubocop`
Expected: Zero offenses.

**Step 3: Run security check**

Run: `bundle exec brakeman --no-pager --quiet`
Expected: No warnings.

**Step 4: Final commit if any fixes needed**
