require "renderers/markdown_html_renderer"

class MarkdownRenderer
  RENDERER = Redcarpet::Markdown.new(
    MarkdownHTMLRenderer.new(hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" }),
    fenced_code_blocks: true,
    autolink: true,
    tables: true,
    strikethrough: true,
    no_intra_emphasis: true,
    space_after_headers: true
  )

  def self.render(markdown)
    return "" if markdown.blank?
    RENDERER.render(markdown)
  end
end
