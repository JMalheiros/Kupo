# Rewrite Views with RubyUI Components

## Summary

Replace hand-coded Tailwind UI elements across all views with RubyUI components. Also replace the category checkbox list in the article form with a multi-select Combobox.

## Component Replacements

### Buttons (`<button>` tags)
All hand-coded submit/action buttons become `Button(...)`:
```ruby
Button(type: :submit) { "Sign in" }
Button(type: :submit, variant: :primary) { "Add" }
```

### Links styled as buttons (`<a>` tags)
All `<a>` tags with button-like styling become `Link(...)`:
```ruby
Link(href: path, variant: :outline, size: :sm, data: { turbo_frame: "modal" }) { "Edit" }
Link(href: path, variant: :primary, size: :sm, data: { turbo_frame: "modal" }) { "New Article" }
Link(href: path, variant: :link) { "Forgot password?" }
```

### Inputs + Form Fields
Raw `<input>` + `<label>` combos become `FormField` > `FormFieldLabel` + `Input`:
```ruby
FormField do
  FormFieldLabel(for: "email_address") { "Email address" }
  Input(type: :email, name: "email_address", id: "email_address", required: true, placeholder: "Enter your email address")
end
```

### Alerts (Flash Messages)
Raw `<p>` flash messages become `Alert` + `AlertDescription`:
```ruby
Alert(variant: :destructive, class: "mb-5") do
  AlertDescription { plain @alert }
end

Alert(variant: :success, class: "mb-5") do
  AlertDescription { plain @notice }
end
```

### Badges
`Components::Admin::StatusBadge` replaced by `Badge` with color mapping:
- `published` -> `:green`
- `scheduled` -> `:yellow`
- `draft` -> `:gray`

Category tags in preview become `Badge(variant: :secondary)`.

### Modal -> Dialog
`Components::Modal` replaced by `Dialog(open: true)` with `DialogContent`:
```ruby
Dialog(open: true) do
  DialogContent(size: :xl) do
    DialogHeader do
      DialogTitle { "Title" }
    end
    DialogMiddle do
      # form content
    end
  end
end
```

The RubyUI dialog controller needs `window.history.back()` added to its `dismiss` method to match the current modal behavior with Turbo frame navigation.

### Headings
Raw `<h1>`/`<h2>` become `Heading(level: N)`.

### Categories: Checkboxes -> Combobox
The article form's category checkboxes become a multi-select Combobox:
```ruby
Combobox(term: "categories") do
  ComboboxTrigger(placeholder: "Select categories")
  ComboboxPopover do
    ComboboxSearchInput(placeholder: "Search categories...")
    ComboboxList do
      ComboboxEmptyState { "No categories found" }
      @categories.each do |category|
        ComboboxItem do
          ComboboxCheckbox(name: "article[category_ids][]", value: category.id, checked: @article.category_ids.include?(category.id))
          span { category.name }
        end
      end
    end
  end
end
```
The hidden field `input(type: "hidden", name: "article[category_ids][]", value: "")` is kept to allow empty selection.

## Files Modified

| File | Changes |
|------|---------|
| `app/views/sessions/new.rb` | Button, Input, FormField, Alert, Heading |
| `app/views/passwords/new.rb` | Button, Input, FormField, Alert, Heading |
| `app/views/passwords/edit.rb` | Button, Input, FormField, Alert, Heading |
| `app/views/admin/articles/index.rb` | Heading, Badge, Link, Button (delete) |
| `app/views/admin/articles/form.rb` | Dialog, Heading, Input, FormField, Button, Combobox (categories) |
| `app/views/admin/categories/index.rb` | Dialog, Heading, Input, FormField, Button |
| `app/views/articles/preview/show.rb` | Heading, Badge, Link |
| `app/components/admin/markdown_preview.rb` | FormFieldLabel |
| `app/javascript/controllers/ruby_ui/dialog_controller.js` | Add history.back() on dismiss |

## Files Removed

- `app/components/modal.rb` — replaced by RubyUI Dialog
- `app/components/admin/status_badge.rb` — replaced by RubyUI Badge
- `app/javascript/controllers/modal_controller.js` — replaced by RubyUI dialog controller
