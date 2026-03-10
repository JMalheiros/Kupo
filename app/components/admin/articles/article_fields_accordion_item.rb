# frozen_string_literal: true

class Components::Admin::Articles::ArticleFieldsAccordionItem < Components::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    AccordionItem do
      AccordionTrigger do
        div(class: "flex items-center gap-1.5 my-2") do
          Lucide::SquarePen(class: "h-4 w-4")
          plain "Article Data"
        end
        AccordionIcon()
      end
      AccordionContent do
        render Components::Admin::Articles::ArticleFields.new(article: @article, categories: @categories)
        div(class: "col-span-3 flex justify-end items-center gap-4 mt-4 mb-4") do
          render Components::Admin::Articles::SubmitButton.new(article: @article)
        end
      end
    end
  end
end
