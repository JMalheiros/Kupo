require "test_helper"

class Articles::ReviewsControllerTest < ActionDispatch::IntegrationTest
  context "unauthenticated" do
    should "redirect to sign in" do
      article = create(:article, :draft)
      post review_article_url(slug: article.slug)
      assert_response :redirect
    end
  end

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

      assert_response :success
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
      assert_response :success
    end
  end

  context "PATCH #update_suggestion (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
      @article = create(:article, :draft, body: "This is a orginal text.")
      @review = create(:article_review, article: @article)
      @suggestion = create(:review_suggestion, article_review: @review)
    end

    should "accept a suggestion and apply the change to article body" do
      patch article_review_suggestion_url(
        slug: @article.slug,
        id: @suggestion.id
      ), params: { status: "accepted" }

      @suggestion.reload
      @article.reload
      assert_equal "accepted", @suggestion.status
      assert_includes @article.body, "This is an original text."
      assert_response :success
    end

    should "reject a suggestion without modifying the article" do
      original_body = @article.body

      patch article_review_suggestion_url(
        slug: @article.slug,
        id: @suggestion.id
      ), params: { status: "rejected" }

      @suggestion.reload
      @article.reload
      assert_equal "rejected", @suggestion.status
      assert_equal original_body, @article.body
      assert_response :success
    end
  end
end
