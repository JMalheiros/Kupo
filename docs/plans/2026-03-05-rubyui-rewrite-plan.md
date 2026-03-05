# RubyUI Component Rewrite Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all hand-coded Tailwind UI elements with RubyUI components and convert category selection to a multi-select Combobox.

**Architecture:** This is a pure view-layer refactor. All Phlex views inherit from `Components::Base` which includes the `RubyUI` module (via `Phlex::Kit`), so RubyUI components are available directly as `Button(...)`, `Input(...)`, etc. — no `render` needed. Existing integration and system tests validate rendered text content and should pass without changes.

**Tech Stack:** Rails 8.1, Phlex, RubyUI (Phlex::Kit), Stimulus, Turbo

---

### Task 1: Rewrite Sessions::New with RubyUI

**Files:**
- Modify: `app/views/sessions/new.rb`

**Step 1: Rewrite the view**

Replace the flash messages, heading, form fields, inputs, and button with RubyUI components:

```ruby
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
```

**Step 2: Run tests**

Run: `bundle exec rails test test/system/articles_test.rb test/controllers/`
Expected: All tests pass (login flow still works, text content unchanged).

**Step 3: Commit**

```bash
git add app/views/sessions/new.rb
git commit -m "Rewrite sessions/new view with RubyUI components"
```

---

### Task 2: Rewrite Passwords::New with RubyUI

**Files:**
- Modify: `app/views/passwords/new.rb`

**Step 1: Rewrite the view**

```ruby
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

      form(action: helpers.passwords_path, method: "post", class: "space-y-5") do
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

        div do
          Button(type: :submit) { "Email reset instructions" }
        end
      end
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add app/views/passwords/new.rb
git commit -m "Rewrite passwords/new view with RubyUI components"
```

---

### Task 3: Rewrite Passwords::Edit with RubyUI

**Files:**
- Modify: `app/views/passwords/edit.rb`

**Step 1: Rewrite the view**

```ruby
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

      form(action: helpers.password_path(@token), method: "post", class: "space-y-5") do
        input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
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
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add app/views/passwords/edit.rb
git commit -m "Rewrite passwords/edit view with RubyUI components"
```

---

### Task 4: Update dialog controller for Turbo frame navigation

**Files:**
- Modify: `app/javascript/controllers/ruby_ui/dialog_controller.js`

**Step 1: Add history.back() to dismiss**

The current `modal_controller.js` calls `window.history.back()` on close to restore the URL after Turbo frame navigation. Add the same to the RubyUI dialog controller:

```javascript
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dialog"
export default class extends Controller {
  static targets = ["content"]
  static values = {
    open: {
      type: Boolean,
      default: false
    },
  }

  connect() {
    if (this.openValue) {
      this.open()
    }
  }

  open(e) {
    e?.preventDefault();
    document.body.insertAdjacentHTML('beforeend', this.contentTarget.innerHTML)
    // prevent scroll on body
    document.body.classList.add('overflow-hidden')
  }

  dismiss() {
    // allow scroll on body
    document.body.classList.remove('overflow-hidden')
    // remove the element
    this.element.remove()

    // Restore URL if dialog was opened via Turbo frame navigation
    if (window.history.length > 1) {
      window.history.back()
    }
  }
}
```

**Step 2: Run system tests**

Run: `bundle exec rails test:system`
Expected: All system tests pass.

**Step 3: Commit**

```bash
git add app/javascript/controllers/ruby_ui/dialog_controller.js
git commit -m "Add history.back() to dialog controller for Turbo frame navigation"
```

---

### Task 5: Rewrite Articles::Preview::Show with RubyUI

**Files:**
- Modify: `app/views/articles/preview/show.rb`

**Step 1: Rewrite the view**

Replace StatusBadge with Badge, category tags with Badge, heading with Heading, and link buttons with Link:

```ruby
# frozen_string_literal: true

class Views::Articles::Preview::Show < Views::Base
  def initialize(article:)
    @article = article
  end

  def view_template
    div(class: "max-w-3xl mx-auto px-4 py-8") do
      article(class: "prose prose-lg dark:prose-invert max-w-none") do
        header(class: "mb-8") do
          div(class: "flex items-center gap-2 mb-4") do
            Badge(variant: status_variant(@article.status)) { plain @article.status.capitalize }

            @article.categories.each do |category|
              Badge(variant: :secondary) { plain category.name }
            end
          end

          Heading(level: 1) { plain @article.title }

          p(class: "text-sm text-muted-foreground mt-2") do
            plain @article.created_at.strftime("%B %d, %Y")
          end
        end

        div(class: "article-body") do
          raw safe(MarkdownRenderer.render(@article.body))
        end
      end

      footer(class: "mt-8 pt-4 border-t border-border flex gap-4") do
        Link(
          href: helpers.edit_article_path(slug: @article.slug),
          variant: :outline,
          size: :sm,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Link(
          href: helpers.export_article_path(slug: @article.slug),
          variant: :outline,
          size: :sm
        ) { "Export Markdown" }
      end
    end

    turbo_frame_tag("modal")
  end

  private

  def status_variant(status)
    case status
    when "published" then :green
    when "scheduled" then :yellow
    when "draft" then :gray
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/articles/previews_controller_test.rb test/system/articles_test.rb`
Expected: All tests pass. Text content like "Published Article", "Export Markdown" still present.

**Step 3: Commit**

```bash
git add app/views/articles/preview/show.rb
git commit -m "Rewrite article preview view with RubyUI components"
```

---

### Task 6: Rewrite Admin::Articles::Index with RubyUI

**Files:**
- Modify: `app/views/admin/articles/index.rb`

**Step 1: Rewrite the view**

Replace heading, link buttons, StatusBadge references, and delete button with RubyUI. Keep the filter nav links as plain `<a>` tags since they are navigation pills (not button-styled links):

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::Index < Views::Base
  def initialize(articles:, categories:, current_category: nil, current_status: nil)
    @articles = articles
    @categories = categories
    @current_category = current_category
    @current_status = current_status
  end

  def view_template
    div(class: "max-w-4xl mx-auto px-4 py-8") do
      div(class: "flex items-center justify-between mb-8") do
        Heading(level: 1) { "Articles" }

        div(class: "flex gap-2") do
          Link(
            href: helpers.categories_path,
            variant: :outline,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "Manage Categories" }

          Link(
            href: helpers.new_article_path,
            variant: :primary,
            size: :sm,
            data: { turbo_frame: "modal" }
          ) { "New Article" }
        end
      end

      # Category filter
      nav(class: "flex flex-wrap gap-2 mb-4") do
        status_params = @current_status ? { status: @current_status } : {}
        a(
          href: helpers.root_path(**status_params),
          class: category_filter_class(nil),
          data: { turbo_frame: "articles" }
        ) { "All" }

        @categories.each do |category|
          a(
            href: helpers.root_path(category: category.slug, **status_params),
            class: category_filter_class(category.slug),
            data: { turbo_frame: "articles" }
          ) { plain category.name }
        end
      end

      # Status filter
      nav(class: "flex gap-2 mb-4") do
        %w[all draft scheduled published].each do |status|
          params_hash = status == "all" ? {} : { status: status }
          params_hash[:category] = @current_category if @current_category
          a(
            href: helpers.root_path(**params_hash),
            class: status_filter_class(status)
          ) { plain status.capitalize }
        end
      end

      turbo_frame_tag("articles") do
        div(class: "space-y-4") do
          @articles.each do |article|
            admin_article_card(article)
          end
        end
      end
    end

    turbo_frame_tag("modal")
  end

  private

  def admin_article_card(article)
    div(class: "flex items-center justify-between p-4 rounded-lg border border-border") do
      a(
        href: helpers.preview_article_path(slug: article.slug),
        class: "flex-1",
        data: { turbo_frame: "_top" }
      ) do
        div(class: "flex items-center gap-3") do
          Badge(variant: status_variant(article.status)) { plain article.status.capitalize }
          h2(class: "text-lg font-medium text-foreground") { plain article.title }
        end
        p(class: "text-sm text-muted-foreground mt-1") do
          if article.published_at
            plain "#{article.status == 'scheduled' ? 'Scheduled for' : 'Published'} #{article.published_at.strftime('%B %d, %Y at %H:%M')}"
          else
            plain "Draft"
          end
        end
      end

      div(class: "flex items-center gap-2") do
        Link(
          href: helpers.edit_article_path(slug: article.slug),
          variant: :ghost,
          size: :sm,
          data: { turbo_frame: "modal" }
        ) { "Edit" }

        Button(
          variant: :ghost,
          size: :sm,
          formaction: helpers.article_path(slug: article.slug),
          formmethod: "post",
          name: "_method",
          value: "delete",
          class: "text-destructive hover:text-destructive/80",
          data: { turbo_confirm: "Are you sure you want to delete this article?" }
        ) { "Delete" }
      end
    end
  end

  def status_variant(status)
    case status
    when "published" then :green
    when "scheduled" then :yellow
    when "draft" then :gray
    end
  end

  def category_filter_class(slug)
    base = "px-4 py-2 rounded-full text-sm font-medium transition-colors"
    if @current_category == slug || (@current_category.nil? && slug.nil?)
      "#{base} bg-primary text-primary-foreground"
    else
      "#{base} bg-secondary text-secondary-foreground hover:bg-accent"
    end
  end

  def status_filter_class(status)
    base = "text-sm transition-colors"
    current = @current_status || "all"
    if current == status
      "#{base} text-foreground font-medium"
    else
      "#{base} text-muted-foreground hover:text-foreground"
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/articles_controller_test.rb test/system/articles_test.rb`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add app/views/admin/articles/index.rb
git commit -m "Rewrite articles index view with RubyUI components"
```

---

### Task 7: Rewrite Admin::Categories::Index with RubyUI Dialog

**Files:**
- Modify: `app/views/admin/categories/index.rb`

**Step 1: Rewrite the view**

Replace Modal with Dialog, heading with DialogTitle, input with Input, button with Button:

```ruby
# frozen_string_literal: true

class Views::Admin::Categories::Index < Views::Base
  def initialize(categories:, new_category: nil)
    @categories = categories
    @new_category = new_category || Category.new
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :sm) do
          DialogHeader do
            DialogTitle { "Manage Categories" }
          end

          DialogMiddle do
            # New category form
            form(action: helpers.categories_path, method: "post", class: "flex gap-2 mb-6") do
              input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
              Input(
                type: :text,
                name: "category[name]",
                value: @new_category.name,
                placeholder: "New category name",
                required: true,
                class: "flex-1"
              )
              Button(type: :submit, size: :sm) { "Add" }
            end

            # Category list
            div(class: "space-y-2") do
              @categories.each do |category|
                div(class: "flex items-center justify-between p-3 rounded-lg border border-border") do
                  span(class: "text-foreground") { plain category.name }
                  Button(
                    variant: :ghost,
                    size: :sm,
                    formaction: helpers.category_path(category),
                    formmethod: "post",
                    name: "_method",
                    value: "delete",
                    class: "text-destructive hover:text-destructive/80",
                    data: { turbo_confirm: "Delete #{category.name}?" }
                  ) { "Delete" }
                end
              end
            end
          end
        end
      end
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/categories_controller_test.rb test/system/articles_test.rb`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add app/views/admin/categories/index.rb
git commit -m "Rewrite categories index with RubyUI Dialog"
```

---

### Task 8: Rewrite Admin::Articles::Form with RubyUI Dialog and Combobox

**Files:**
- Modify: `app/views/admin/articles/form.rb`

**Step 1: Rewrite the view**

Replace Modal with Dialog, inputs with Input/FormField, button with Button, and category checkboxes with Combobox multi-select:

```ruby
# frozen_string_literal: true

class Views::Admin::Articles::Form < Views::Base
  def initialize(article:, categories:)
    @article = article
    @categories = categories
  end

  def view_template
    turbo_frame_tag("modal") do
      Dialog(open: true) do
        DialogContent(size: :xl) do
          DialogHeader do
            DialogTitle { plain @article.new_record? ? "New Article" : "Edit Article" }
          end

          DialogMiddle do
            form_content
          end
        end
      end
    end
  end

  private

  def form_content
    url = @article.new_record? ? helpers.articles_path : helpers.article_path(slug: @article.slug)
    method = @article.new_record? ? "post" : "patch"

    form_with_tag(url: url, method: method) do
      # Title
      FormField(class: "mb-4") do
        FormFieldLabel(for: "article_title") { "Title" }
        Input(
          type: :text,
          name: "article[title]",
          id: "article_title",
          value: @article.title,
          required: true
        )
        render_errors_for(:title)
      end

      # Categories (Combobox multi-select)
      div(class: "mb-4") do
        FormField do
          FormFieldLabel { "Categories" }
          Combobox(term: "categories") do
            ComboboxTrigger(placeholder: "Select categories")

            ComboboxPopover do
              ComboboxSearchInput(placeholder: "Search categories...")

              ComboboxList do
                ComboboxEmptyState { "No categories found" }

                @categories.each do |category|
                  ComboboxItem do
                    ComboboxCheckbox(
                      name: "article[category_ids][]",
                      value: category.id,
                      checked: @article.category_ids.include?(category.id)
                    )
                    span { plain category.name }
                  end
                end
              end
            end
          end
          # Hidden field to allow empty category_ids
          input(type: "hidden", name: "article[category_ids][]", value: "")
        end
      end

      # Markdown editor with preview
      div(class: "mb-4") do
        render Components::Admin::MarkdownPreview.new(body: @article.body)
      end

      # Image upload
      div(class: "mb-6", data: { controller: "image-upload" }) do
        FormField do
          FormFieldLabel { "Upload Image" }
          Input(
            type: :file,
            accept: "image/*",
            data: { image_upload_target: "input", action: "change->image-upload#upload" }
          )
        end
      end

      # Submit
      div(class: "flex justify-end gap-4") do
        Button(type: :submit) { plain @article.new_record? ? "Create Article" : "Update Article" }
      end
    end
  end

  def form_with_tag(url:, method:, &block)
    actual_method = method == "patch" ? "post" : method
    form(action: url, method: actual_method, class: "space-y-4") do
      input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
      input(type: "hidden", name: "_method", value: method) if method == "patch"
      yield
    end
  end

  def render_errors_for(field)
    return unless @article.errors[field].any?
    @article.errors[field].each do |error|
      FormFieldError { plain error }
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/articles_controller_test.rb test/system/articles_test.rb`
Expected: All tests pass. Article creation/update still works with category_ids params.

**Step 3: Commit**

```bash
git add app/views/admin/articles/form.rb
git commit -m "Rewrite article form with RubyUI Dialog, FormField, and Combobox"
```

---

### Task 9: Update MarkdownPreview with RubyUI FormFieldLabel

**Files:**
- Modify: `app/components/admin/markdown_preview.rb`

**Step 1: Rewrite the labels**

```ruby
# frozen_string_literal: true

class Components::Admin::MarkdownPreview < Components::Base
  def initialize(body: "")
    @body = body
  end

  def view_template
    div(
      class: "grid grid-cols-2 gap-4 h-[60vh]",
      data: { controller: "markdown-preview" }
    ) do
      # Editor pane
      div(class: "flex flex-col") do
        FormFieldLabel(class: "mb-2") { "Markdown" }
        textarea(
          name: "article[body]",
          class: "flex-1 w-full p-4 font-mono text-sm border border-input rounded-lg bg-background text-foreground resize-none focus:outline-none focus:ring-2 focus:ring-ring",
          data: { markdown_preview_target: "input", action: "input->markdown-preview#update" },
          placeholder: "Write your article in markdown..."
        ) { plain @body }
      end

      # Preview pane
      div(class: "flex flex-col") do
        FormFieldLabel(class: "mb-2") { "Preview" }
        div(
          class: "flex-1 overflow-y-auto p-4 border border-input rounded-lg bg-background prose prose-sm dark:prose-invert max-w-none",
          data: { markdown_preview_target: "preview" }
        ) do
          raw safe(MarkdownRenderer.render(@body)) if @body.present?
        end
      end
    end
  end
end
```

**Step 2: Run tests**

Run: `bundle exec rails test test/controllers/articles/markdown_previews_controller_test.rb`
Expected: All tests pass.

**Step 3: Commit**

```bash
git add app/components/admin/markdown_preview.rb
git commit -m "Use RubyUI FormFieldLabel in MarkdownPreview component"
```

---

### Task 10: Remove replaced components and controller

**Files:**
- Delete: `app/components/modal.rb`
- Delete: `app/components/admin/status_badge.rb`
- Delete: `app/javascript/controllers/modal_controller.js`

**Step 1: Delete the files**

```bash
rm app/components/modal.rb
rm app/components/admin/status_badge.rb
rm app/javascript/controllers/modal_controller.js
```

**Step 2: Run full test suite**

Run: `bundle exec rails test && bundle exec rails test:system`
Expected: All tests pass. No references to deleted components remain.

**Step 3: Run linting and security checks**

Run: `bundle exec rubocop && bundle exec brakeman --no-pager --quiet`
Expected: No offenses, no warnings.

**Step 4: Commit**

```bash
git add -A
git commit -m "Remove Modal, StatusBadge, and modal controller replaced by RubyUI"
```
