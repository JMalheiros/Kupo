# frozen_string_literal: true

class Components::Admin::Articles::PlanPreviewAccordionItem < Components::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    AccordionItem do
      AccordionTrigger do
        div(class: "flex items-center gap-1.5 my-2") do
          Lucide::NotebookPen(class: "h-4 w-4")
          plain "View Plan"
        end
        AccordionIcon()
      end

      AccordionContent do
        div(class: "h-[30vh] overflow-y-auto pb-0 prose prose-sm dark:prose-invert max-w-none") do
          raw safe(MarkdownRenderer.render(@article.plan))
        end
      end
    end
  end
end
