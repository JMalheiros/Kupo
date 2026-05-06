# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :xxl) do
          DialogHeader do
            DialogTitle { plain @article.new_record? ? "New Article" : "Edit Article" }
          end

          DialogMiddle(class: "py-0") do
            if @article.persisted?
              tabbed_content
            else
              new_article_tabs
            end
          end
        end
      end
    end
  end

  private

  def tabbed_content
    div do
      Tabs(default: "edit") do
        TabsList do
          TabsTrigger(value: "plan") { "Plan" }
          TabsTrigger(value: "edit") { "Edit" }
          TabsTrigger(value: "review") { "Review" }
          TabsTrigger(value: "translate") { "Translate" }
        end

        # Edit and Plan tabs are inside the same form
        article_form_with_plan

        # Review tab is outside the form (has its own forms)
        TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "review") do
          render Components::Admin::Reviews.new(article: @article)
        end

        TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "translate") do
          render Components::Admin::Translations.new(article: @article)
        end
      end
    end
  end

  def new_article_tabs
    div do
      Tabs(default: "edit") do
        TabsList do
          TabsTrigger(value: "plan") { "Plan" }
          TabsTrigger(value: "edit") { "Edit" }
        end

        article_form_with_plan
      end
    end
  end

  def article_form_with_plan
    url = @article.new_record? ? articles_path : article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4 mb-0", value: "edit") do
        Accordion do
          render Components::Admin::Articles::ArticleFieldsAccordionItem.new(article: @article, categories: @categories)
          if @article.plan.present?
            render Components::Admin::Articles::PlanPreviewAccordionItem.new(article: @article)
          end
        end
        render Components::Admin::Articles::MarkdownEditor.new(article: @article, required: !@article.new_record?)
      end

      TabsContent(class: "col-span-3 rounded-lg border border-border bg-muted/50 p-4", value: "plan") do
        render Components::Admin::Articles::ArticlePlan.new(article: @article)
        render Components::Admin::Articles::SubmitButton.new(article: @article, label: "Save Plan", class: "mt-4")
      end
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    Form(action: url, method: actual_method, class: "grid grid-cols-3 space-y-4 gap-3") do
      Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
      Input(type: :hidden, name: "_method", value: method) if method == "patch"
      yield
    end
  end
end
