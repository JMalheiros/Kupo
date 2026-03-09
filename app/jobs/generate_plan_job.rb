# frozen_string_literal: true

class GeneratePlanJob < ApplicationJob
  queue_as :default

  def perform(article, user)
    plan = PlanService.new.generate_plan(article)

    if plan.present?
      article.update!(plan: plan)
      broadcast_plan(article, user)
    else
      broadcast_error(user)
    end
  rescue => e
    Rails.logger.error("GeneratePlanJob failed: #{e.class} - #{e.message}")
    broadcast_error(user)
  end

  private

  def broadcast_plan(article, user)
    html = ApplicationController.render(
      Components::Admin::Articles::ArticlePlan.new(article: article),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "article-plan-editor",
      html: html
    )
  end

  def broadcast_error(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      user,
      target: "article-plan-editor",
      html: "<p id='article-plan-editor' class='text-sm text-destructive'>Plan generation failed. Please try again.</p>"
    )
  end
end
