# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def initialize(alert: nil, email_address: nil)
    @alert = alert
    @email_address = email_address
  end

  def view_template
    div(class: "max-w-md mx-auto px-4 py-12") do
      if @alert
        p(id: "alert", class: "py-2 px-3 mb-5 text-sm font-medium rounded-lg bg-destructive/10 text-destructive") { plain @alert }
      end

      h1(class: "text-3xl font-bold text-foreground mb-8") { "Forgot your password?" }

      form(action: helpers.passwords_path, method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)

        div do
          label(for: "email_address", class: "block text-sm font-medium text-foreground mb-1") { "Email address" }
          input(
            type: "email",
            name: "email_address",
            id: "email_address",
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Enter your email address",
            value: @email_address,
            class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          )
        end

        div do
          button(
            type: "submit",
            class: "px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors font-medium cursor-pointer"
          ) { "Email reset instructions" }
        end
      end
    end
  end
end
