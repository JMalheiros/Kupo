# frozen_string_literal: true

class Views::Admin::Articles::PublishSheet < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    Sheet do
      SheetTrigger do
        Button(variant: :ghost, size: :md) { "Publish" }
      end

      SheetContent(class: "text-sm") do
        SheetHeader do
          SheetTitle { "Publish Article" }
          SheetDescription { plain @article.title }
        end

        SheetMiddle do
          # Publish Now
          form(action: publish_article_path(slug: @article.slug), method: "post", class: "mb-4") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            input(type: "hidden", name: "publish_action", value: "now")
            Button(type: :submit, class: "w-full") { "Publish Now" }
          end

          div(class: "relative mb-2") do
            div(class: "absolute inset-0 flex items-center") do
              div(class: "w-full border-t border-border")
            end
            div(class: "relative flex justify-center text-xs uppercase") do
              span(class: "bg-background px-2 text-muted-foreground") { "Or schedule" }
            end
          end

          # Schedule
          form(action: publish_article_path(slug: @article.slug), method: "post") do
            input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
            input(type: "hidden", name: "publish_action", value: "schedule")

            div(class: "space-y-2") do
              Input(
                type: :hidden,
                name: "published_at",
                id: "publish-date-#{@article.slug}",
                data: { controller: "ruby-ui--calendar-input" }
              )

              div(class: "flex justify-center") do
                Calendar(
                  input_id: "#publish-date-#{@article.slug}",
                  selected_date: @article.published_at || Date.tomorrow,
                  class: "rounded-md border shadow"
                )
              end

              div do
                FormFieldLabel(for: "publish-time-#{@article.slug}") { "Time" }
                Input(
                  type: :time,
                  name: "publish_time",
                  id: "publish-time-#{@article.slug}",
                  value: (@article.published_at || Time.current).strftime("%H:%M")
                )
              end

              Button(type: :submit, variant: :outline, class: "w-full") { "Schedule" }
            end
          end
        end
      end
    end
  end
end
