# frozen_string_literal: true

class Components::Admin::Toast < Components::Base
  def initialize(notice: nil, alert: nil, container: true)
    @notice = notice
    @alert = alert
    @container = container
  end

  def view_template
    if @container
      div(id: "toast-container", class: "fixed top-4 right-4 z-[100] space-y-2") do
        toast_items
      end
    else
      toast_items
    end
  end

  private

  def toast_items
    toast_item { @notice } if @notice
    toast_item(variant: :destructive) { @alert } if @alert
  end

  def toast_item(variant: nil, &block)
    Alert(
      variant: variant,
      class: "w-80 shadow-lg cursor-pointer",
      data: {
        controller: "toast",
        action: "click->toast#dismiss"
      },
      &block
    )
  end
end
