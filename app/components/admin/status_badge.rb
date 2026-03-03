# frozen_string_literal: true

class Components::Admin::StatusBadge < Components::Base
  def initialize(status:)
    @status = status
  end

  def view_template
    span(class: badge_class) { plain @status.capitalize }
  end

  private

  def badge_class
    base = "text-xs font-medium px-2 py-1 rounded-full"
    case @status
    when "published"
      "#{base} bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
    when "scheduled"
      "#{base} bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
    when "draft"
      "#{base} bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200"
    end
  end
end
