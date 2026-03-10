# frozen_string_literal: true

class Components::Admin::Articles::SubmitButton < Components::Base
  def initialize(article: nil, label: nil, class: nil)
    @article = article
    @label = label
    @extra_class = binding.local_variable_get(:class)
  end

  def view_template
    div(class: "col-span-3 flex justify-end gap-4 #{@extra_class}".strip) do
      Button(type: :submit, size: :sm) { plain button_label }
    end
  end

  private

  def button_label
    @label || (@article&.new_record? ? "Create Article" : "Update Article")
  end
end
