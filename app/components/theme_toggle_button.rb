# frozen_string_literal: true

class Components::ThemeToggleButton < Components::Base
  def view_template
    ThemeToggle do
      SetLightMode do
        Button(variant: :ghost, icon: true) do
          Lucide::Sun(variant: :filled, class: "w-4 h-4")
        end
      end

      SetDarkMode do
        Button(variant: :ghost, icon: true) do
          Lucide::Moon(variant: :filled, class: "w-4 h-4")
        end
      end
    end
  end
end
