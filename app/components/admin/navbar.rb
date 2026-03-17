# frozen_string_literal: true

class Components::Admin::Navbar < Components::Base
  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-4 flex items-center justify-between") do
      img(src: "/icon.png", alt: "Kupo Logo", class: "w-8 h-8 mr-2 bg-transparent")
      a(href: "/", class: "text-xl font-bold text-foreground hover:text-primary transition-colors") { "KUPO" }

      if authenticated?
        nav(class: "flex items-center gap-4") do
          Link(
            href: edit_settings_path,
            variant: :ghost,
            icon: true,
            data: { turbo_frame: "modal" }
          ) do
            Lucide::Settings(class: "w-4 h-4")
          end

          render Components::ThemeToggleButton.new

          Form(action: session_path(Current.session), method: "post") do
            Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
            Input(type: :hidden, name: "_method", value: "delete")
            Button(type: :submit, variant: :ghost, size: :sm, class: "text-muted-foreground") { "Sign out" }
          end
        end
      end
    end
  end
end
