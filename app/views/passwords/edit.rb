# frozen_string_literal: true

class Views::Passwords::Edit < Views::Base
  def initialize(token:, alert: nil)
    @token = token
    @alert = alert
  end

  def view_template
    div(class: "max-w-md mx-auto px-4 py-12") do
      if @alert
        Alert(variant: :destructive, class: "mb-5") do
          AlertDescription { plain @alert }
        end
      end

      Heading(level: 1, class: "mb-8") { "Update your password" }

      form(action: password_path(@token), method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "put")

        FormField do
          FormFieldLabel(for: "password") { "New password" }
          Input(
            type: :password,
            name: "password",
            id: "password",
            required: true,
            autocomplete: "new-password",
            placeholder: "Enter new password",
            maxlength: 72
          )
        end

        FormField do
          FormFieldLabel(for: "password_confirmation") { "Confirm password" }
          Input(
            type: :password,
            name: "password_confirmation",
            id: "password_confirmation",
            required: true,
            autocomplete: "new-password",
            placeholder: "Repeat new password",
            maxlength: 72
          )
        end

        div do
          Button(type: :submit) { "Save" }
        end
      end
    end
  end
end
