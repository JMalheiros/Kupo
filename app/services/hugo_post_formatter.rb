# frozen_string_literal: true

class HugoPostFormatter
  IMAGE_PATTERN = /!\[([^\]]*)\]\(\/rails\/active_storage\/blobs\/redirect\/([^\/]+)\/([^)]+)\)/

  def initialize(article)
    @article = article
  end

  def format
    "#{front_matter}#{body}"
  end

  def image_references
    @article.body.scan(IMAGE_PATTERN).map do |alt, signed_id, filename|
      { alt: alt, signed_id: signed_id, filename: filename }
    end
  end

  private

  def front_matter
    categories = @article.categories.pluck(:name).map { |n| %("#{n}") }.join(", ")

    <<~YAML
      ---
      title: "#{@article.title}"
      date: #{@article.published_at.iso8601}
      categories: [#{categories}]
      author: "#{ENV['HUGO_AUTHOR_NAME']}"
      draft: false
      ---

    YAML
  end

  def body
    @article.body.gsub(IMAGE_PATTERN) do |_match|
      alt = Regexp.last_match(1)
      filename = Regexp.last_match(3)
      "![#{alt}](#{filename})"
    end
  end
end
