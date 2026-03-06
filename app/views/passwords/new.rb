# frozen_string_literal: true

class Views::Passwords::New < Views::Base
  def initialize(alert: nil, email_address: nil)
    @alert = alert
    @email_address = email_address
  end

  def view_template
    div(class: "max-w-md mx-auto px-4 py-12") do
      if @alert
        Alert(variant: :destructive, class: "mb-5") do
          AlertDescription { plain @alert }
        end
      end

      Heading(level: 1, class: "mb-8") { "Forgot your password?" }

      form(action: passwords_path, method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

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

        div do
          Button(type: :submit) { "Email reset instructions" }
        end
      end
    end
  end
end
