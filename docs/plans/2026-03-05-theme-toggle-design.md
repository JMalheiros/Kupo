# Theme Toggle Design

## Summary

Add a dark/light theme toggle to the application header using the existing RubyUI ThemeToggle component.

## Details

- Place the toggle in the header nav, next to "Sign out" (visible only when authenticated)
- Use sun/moon SVG icons inside SetLightMode/SetDarkMode components
- Add anti-FOUC inline script in `<head>` to apply saved theme before first paint
- Leverages existing dark mode CSS variables and ThemeToggle Stimulus controller

## Files Modified

- `app/views/layouts/application.html.erb` — add theme toggle + anti-FOUC script
