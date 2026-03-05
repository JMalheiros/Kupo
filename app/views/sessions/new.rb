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

      Heading(level: 1, class: "mb-8") { "Sign in" }

      form(action: helpers.session_path, method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)

        FormField do
          FormFieldLabel(for: "email_address") { "Email address" }
          Input(
            type: :email,
            name: "email_address",
            id: "email_address",
            required: true,
            autofocus: true,
            autocomplete: "username",
            placeholder: "Enter your email address",
            value: @email_address
          )
        end

        FormField do
          FormFieldLabel(for: "password") { "Password" }
          Input(
            type: :password,
            name: "password",
            id: "password",
            required: true,
            autocomplete: "current-password",
            placeholder: "Enter your password",
            maxlength: 72
          )
        end

        div(class: "flex items-center justify-between gap-4") do
          Button(type: :submit) { "Sign in" }

          Link(href: helpers.new_password_path, variant: :link) { "Forgot password?" }
        end
      end
    end
  end

  private

  def flash_messages
    if @alert
      Alert(variant: :destructive, class: "mb-5") do
        AlertDescription { plain @alert }
      end
    end

    if @notice
      Alert(variant: :success, class: "mb-5") do
        AlertDescription { plain @notice }
      end
    end
  end
end
