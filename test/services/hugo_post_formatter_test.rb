# frozen_string_literal: true

require "test_helper"

class HugoPostFormatterTest < ActiveSupport::TestCase
  context "#format" do
    should "generate Hugo front matter with title, date, categories, and draft false" do
      tech = create(:category, name: "Tech")
      rails_cat = create(:category, name: "Rails")
      article = create(:article, :published,
        title: "My Article",
        body: "Some content here.",
        published_at: Time.zone.parse("2026-03-05 14:30:00"))
      article.categories << [ tech, rails_cat ]

      result = HugoPostFormatter.new(article).format

      assert_match "---\n", result
      assert_match 'title: "My Article"', result
      assert_match "date: 2026-03-05T", result
      assert_match "categories:", result
      assert_match "Tech", result
      assert_match "Rails", result
      assert_match "draft: false", result
      assert_match "---\n\nSome content here.", result
    end

    should "rewrite ActiveStorage image URLs to relative paths" do
      article = create(:article, :published,
        title: "Image Post",
        body: "Hello\n\n![photo.png](/rails/active_storage/blobs/redirect/abc123/photo.png)\n\nMore text\n\n![diagram.jpg](/rails/active_storage/blobs/redirect/def456/diagram.jpg)")

      result = HugoPostFormatter.new(article).format

      assert_match "![photo.png](photo.png)", result
      assert_match "![diagram.jpg](diagram.jpg)", result
      refute_match "/rails/active_storage", result
    end

    should "leave body unchanged when there are no images" do
      article = create(:article, :published, title: "No Images", body: "Just text.")

      result = HugoPostFormatter.new(article).format

      assert_match "Just text.", result
    end
  end

  context "#image_references" do
    should "return list of image filenames and signed IDs from body" do
      article = create(:article, :published,
        body: "![photo.png](/rails/active_storage/blobs/redirect/abc123/photo.png)\n![diagram.jpg](/rails/active_storage/blobs/redirect/def456/diagram.jpg)")

      refs = HugoPostFormatter.new(article).image_references

      assert_equal 2, refs.length
      assert_equal({ alt: "photo.png", signed_id: "abc123", filename: "photo.png" }, refs[0])
      assert_equal({ alt: "diagram.jpg", signed_id: "def456", filename: "diagram.jpg" }, refs[1])
    end

    should "return empty array when no images" do
      article = create(:article, :published, body: "No images here.")

      refs = HugoPostFormatter.new(article).image_references

      assert_empty refs
    end
  end
end
