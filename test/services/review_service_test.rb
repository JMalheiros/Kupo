require "test_helper"

class ReviewServiceTest < ActiveSupport::TestCase
  setup do
    @article = create(:article, :draft, title: "My Article", body: "This is a test artcle about Ruby on Rails.")
  end

  should "return parsed content review suggestions" do
    fake_response = {
      "suggestions" => [
        { "category" => "grammar", "original_text" => "artcle", "suggested_text" => "article", "explanation" => "Typo fix" }
      ]
    }.to_json

    service = ReviewService.new
    service.define_singleton_method(:call_llm) { |_prompt, _schema| fake_response }

    result = service.content_review(@article)
    assert_equal 1, result.length
    assert_equal "grammar", result.first[:category]
    assert_equal "artcle", result.first[:original_text]
    assert_equal "article", result.first[:suggested_text]
    assert_equal "Typo fix", result.first[:explanation]
  end

  should "return parsed seo review suggestions" do
    fake_response = {
      "suggestions" => [
        { "category" => "title", "original_text" => "My Article", "suggested_text" => "Ruby on Rails Guide", "explanation" => "More descriptive" }
      ]
    }.to_json

    service = ReviewService.new
    service.define_singleton_method(:call_llm) { |_prompt, _schema| fake_response }

    result = service.seo_review(@article)
    assert_equal 1, result.length
    assert_equal "title", result.first[:category]
    assert_equal "My Article", result.first[:original_text]
    assert_equal "Ruby on Rails Guide", result.first[:suggested_text]
  end

  should "return empty array on invalid JSON response" do
    service = ReviewService.new
    service.define_singleton_method(:call_llm) { |_prompt, _schema| "not valid json" }

    result = service.content_review(@article)
    assert_equal [], result
  end

  should "return empty array when suggestions key is missing" do
    fake_response = { "other" => "data" }.to_json

    service = ReviewService.new
    service.define_singleton_method(:call_llm) { |_prompt, _schema| fake_response }

    result = service.content_review(@article)
    assert_equal [], result
  end
end
