require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  setup do
    @renderer = MarkdownRenderer
  end

  should "render basic markdown to HTML" do
    html = @renderer.render("# Hello\n\nWorld")
    assert_includes html, "<h1>Hello</h1>"
    assert_includes html, "<p>World</p>"
  end

  should "render bold and italic" do
    html = @renderer.render("**bold** and *italic*")
    assert_includes html, "<strong>bold</strong>"
    assert_includes html, "<em>italic</em>"
  end

  should "render fenced code blocks with syntax highlighting" do
    markdown = "```ruby\nputs 'hello'\n```"
    html = @renderer.render(markdown)
    assert_includes html, "<pre"
    assert_includes html, "highlight"
  end

  should "render tables" do
    markdown = "| A | B |\n|---|---|\n| 1 | 2 |"
    html = @renderer.render(markdown)
    assert_includes html, "<table>"
  end

  should "autolink URLs" do
    html = @renderer.render("Visit https://example.com")
    assert_includes html, '<a href="https://example.com"'
  end

  should "render strikethrough" do
    html = @renderer.render("~~deleted~~")
    assert_includes html, "<del>deleted</del>"
  end

  should "return empty string for nil input" do
    assert_equal "", @renderer.render(nil)
  end

  should "return empty string for blank input" do
    assert_equal "", @renderer.render("")
  end
end
