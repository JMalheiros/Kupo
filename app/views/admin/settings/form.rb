# frozen_string_literal: true

class Views::Admin::Settings::Form < Views::Base
  def initialize(setting:, user:)
    @setting = setting
    @user = user
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :xl) do
          DialogHeader do
            DialogTitle { "Settings" }
          end

          DialogMiddle(class: "py-0") do
            Tabs(default: "llm") do
              TabsList do
                TabsTrigger(value: "llm") { "LLM & API Keys" }
                TabsTrigger(value: "prompts") { "Prompts" }
              end

              Form(action: settings_path, method: "post", class: "space-y-6") do
                Input(type: :hidden, name: "authenticity_token", value: form_authenticity_token)
                Input(type: :hidden, name: "_method", value: "patch")

                TabsContent(class: "rounded-lg border border-border bg-muted/50 p-4", value: "llm") do
                  llm_section
                  api_keys_section
                end

                TabsContent(class: "rounded-lg border border-border bg-muted/50 p-4", value: "prompts") do
                  prompts_section
                end

                div(class: "flex justify-end py-4") do
                  Button(type: :submit) { "Save Settings" }
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def llm_section
    Heading(level: 3, class: "mb-4") { "LLM Configuration" }

    div(class: "grid grid-cols-2 gap-4 mb-6") do
      FormField do
        FormFieldLabel { "Provider" }
        Select(name: "setting[llm_provider]", default: @setting.llm_provider) do
          SelectTrigger do
            SelectValue(placeholder: "Select provider")
          end
          SelectContent do
            ApiKey::PROVIDERS.each do |provider|
              SelectItem(value: provider) { provider.capitalize }
            end
          end
          SelectInput(name: "setting[llm_provider]")
        end
      end

      FormField do
        FormFieldLabel { "Model" }
        Input(
          type: :text,
          name: "setting[llm_model]",
          value: @setting.llm_model,
          placeholder: "e.g. gemini-3-flash"
        )
      end
    end
  end

  def api_keys_section
    Heading(level: 3, class: "mb-4") { "API Keys" }

    div(class: "space-y-3") do
      @user.api_keys.sort_by { |k| ApiKey::PROVIDERS.index(k.provider) || 99 }.each_with_index do |api_key, index|
        div(class: "grid grid-cols-3 gap-3 items-end") do
          FormField do
            FormFieldLabel { "Provider" } if index == 0
            div(class: "flex h-9 items-center rounded-md border border-input bg-muted px-3 text-sm text-muted-foreground") do
              plain api_key.provider.capitalize
            end
            Input(type: :hidden, name: "user[api_keys_attributes][#{index}][provider]", value: api_key.provider)
            Input(type: :hidden, name: "user[api_keys_attributes][#{index}][id]", value: api_key.id) if api_key.persisted?
          end

          FormField(class: "col-span-2") do
            if api_key.ollama?
              FormFieldLabel { "URL" } if index == 0
              Input(
                type: :text,
                name: "user[api_keys_attributes][#{index}][url]",
                value: api_key.persisted? ? api_key.url : "",
                placeholder: "http://localhost:11434"
              )
            else
              FormFieldLabel { "API Key" } if index == 0
              Input(
                type: :password,
                name: "user[api_keys_attributes][#{index}][api_key]",
                value: api_key.persisted? ? api_key.api_key : "",
                placeholder: "Enter your #{api_key.provider.capitalize} API key"
              )
            end
          end
        end
      end
    end
  end

  def prompts_section
    Heading(level: 3, class: "mb-4") { "Prompts" }

    div(class: "space-y-4") do
      prompt_field("Content Review Prompt", "setting[content_review_prompt]", @setting.content_review_prompt)
      prompt_field("SEO Review Prompt", "setting[seo_review_prompt]", @setting.seo_review_prompt)
      prompt_field("Translation Prompt", "setting[translation_prompt]", @setting.translation_prompt)
    end
  end

  def prompt_field(label, name, value)
    FormField do
      FormFieldLabel { label }
      Textarea(
        name: name,
        class: "min-h-[20vh] p-3 font-mono rounded-lg text-foreground resize-none",
        placeholder: "Enter prompt..."
      ) { plain value }
    end
  end
end
