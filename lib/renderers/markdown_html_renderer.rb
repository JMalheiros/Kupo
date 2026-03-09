# frozen_string_literal: true

require "rouge"
require "rouge/plugins/redcarpet"

class MarkdownHTMLRenderer < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet

  # Supports dimension syntax in alt text: ![alt =WIDTHxHEIGHT](url)
  # Examples:
  #   ![photo =300x200](image.png)  => width="300" height="200"
  #   ![photo =300](image.png)      => width="300"
  #   ![photo](image.png)           => no dimensions
  def image(link, title, alt_text)
    alt, width, height = parse_image_dimensions(alt_text)

    attrs = [ %(src="#{link}"), %(alt="#{alt}") ]
    attrs << %(title="#{title}") if title.present?
    attrs << %(width="#{width}") if width.present?
    attrs << %(height="#{height}") if height.present?

    "<img #{attrs.join(" ")} />"
  end

  private

  def parse_image_dimensions(alt_text)
    if alt_text =~ /^(.*)\s+=(\d+)x(\d+)\s*$/
      [ $1.strip, $2, $3 ]
    elsif alt_text =~ /^(.*)\s+=(\d+)\s*$/
      [ $1.strip, $2, nil ]
    else
      [ alt_text, nil, nil ]
    end
  end
end
