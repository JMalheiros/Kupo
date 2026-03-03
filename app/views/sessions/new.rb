# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  def initialize(alert: nil, notice: nil, email_address: nil)
    @alert = alert
    @notice = notice
    @email_address = email_address
  end

  def view_template
    div(class: "max-w-md mx-auto px-4 py-12") do
      flash_messages

      h1(class: "text-3xl font-bold text-foreground mb-8") { "Sign in" }

      form(action: helpers.session_path, method: "post", class: "space-y-5") do
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
          label(for: "password", class: "block text-sm font-medium text-foreground mb-1") { "Password" }
          input(
            type: "password",
            name: "password",
            id: "password",
            required: true,
            autocomplete: "current-password",
            placeholder: "Enter your password",
            maxlength: 72,
            class: "w-full px-4 py-2 border border-input rounded-lg bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          )
        end

        div(class: "flex items-center justify-between gap-4") do
          button(
            type: "submit",
            class: "px-6 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors font-medium cursor-pointer"
          ) { "Sign in" }

          a(
            href: helpers.new_password_path,
            class: "text-sm text-muted-foreground hover:text-foreground transition-colors"
          ) { "Forgot password?" }
        end
      end
    end
  end

  private

  def flash_messages
    if @alert
      p(id: "alert", class: "py-2 px-3 mb-5 text-sm font-medium rounded-lg bg-destructive/10 text-destructive") { plain @alert }
    end

    if @notice
      p(id: "notice", class: "py-2 px-3 mb-5 text-sm font-medium rounded-lg bg-green-500/10 text-green-700 dark:text-green-400") { plain @notice }
    end
  end
end
