require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  subject { build(:article) }

  context "validations" do
    should validate_presence_of(:title)
    should validate_presence_of(:body)
    should validate_uniqueness_of(:slug)
    should validate_inclusion_of(:status).in_array(%w[draft scheduled publishing published])
  end

  context "slug generation" do
    should "auto-generate slug from title before validation" do
      article = build(:article, title: "My First Post", slug: nil)
      article.valid?
      assert_equal "my-first-post", article.slug
    end

    should "not overwrite an existing slug" do
      article = build(:article, title: "My Post", slug: "custom-slug")
      article.valid?
      assert_equal "custom-slug", article.slug
    end

    should "generate unique slugs for duplicate titles" do
      create(:article, title: "My Post", slug: "my-post")
      article = build(:article, title: "My Post", slug: nil)
      article.valid?
      assert_match(/\Amy-post-\h+\z/, article.slug)
    end
  end

  context "scopes" do
    setup do
      @draft = create(:article, :draft)
      @scheduled = create(:article, :scheduled)
      @published = create(:article, :published)
    end

    should "return only published articles" do
      assert_equal [ @published ], Article.published.to_a
    end

    should "return only draft articles" do
      assert_equal [ @draft ], Article.drafts.to_a
    end

    should "return only scheduled articles" do
      assert_equal [ @scheduled ], Article.scheduled.to_a
    end

    should "order published articles by published_at desc" do
      older = create(:article, :published, published_at: 2.hours.ago)
      assert_equal [ @published, older ], Article.published.recent.to_a
    end
  end

  context "associations" do
    should have_many(:article_categories).dependent(:destroy)
    should have_many(:categories).through(:article_categories)
    should have_many_attached(:images)
  end

  context "publishing" do
    should "publish now sets status to publishing and enqueues job" do
      article = create(:article, :draft)
      article.publish_now!

      assert_equal "publishing", article.status
      assert_not_nil article.published_at
      assert article.published_at <= Time.current
    end

    should "schedule sets status to scheduled with future date" do
      article = create(:article, :draft)
      future = 2.days.from_now
      article.schedule!(future)

      assert_equal "scheduled", article.status
      assert_equal future.to_i, article.published_at.to_i
    end
  end
end
