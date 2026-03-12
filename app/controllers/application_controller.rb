class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def broadcast_toast(notice: nil, alert: nil)
    html = ApplicationController.render(
      Components::Admin::Toast.new(notice: notice, alert: alert, container: false),
      layout: false
    )

    Turbo::StreamsChannel.broadcast_append_to(
      Current.user,
      target: "toast-container",
      html: html
    )
  end
end
