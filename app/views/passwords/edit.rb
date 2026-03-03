# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:, alert: nil)
    @token = token
    @alert = alert
  end

  def view_template
    div(class: "max-w-md mx-auto px-4 py-12") do
      if @alert
        p(id: "alert", class: "py-2 px-3 mb-5 text-sm font-medium rounded-lg bg-destructive/10 text-destructive") { plain @alert }
      end

      h1(class: "text-3xl font-bold text-foreground mb-8") { "Update your password" }

      form(action: helpers.password_path(@token), method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
        input(type: "hidden", name: "_method", value: "put")

        div do
          label(for: "password", class: "block text-sm font-medium text-foreground mb-1") { "New password" }
          input(
            type: "password",
            name: "password",
            id: "password",
            required: true,
            autocomplete: "new-password",
            placeholder: "Enter new password",
            maxlength: 72,
            class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          )
        end

        div do
          label(for: "password_confirmation", class: "block text-sm font-medium text-foreground mb-1") { "Confirm password" }
          input(
            type: "password",
            name: "password_confirmation",
            id: "password_confirmation",
            required: true,
            autocomplete: "new-password",
            placeholder: "Repeat new password",
            maxlength: 72,
            class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          )
        end

        div do
          button(
            type: "submit",
            class: "px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors font-medium cursor-pointer"
          ) { "Save" }
        end
      end
    end
  end
end
