# frozen_string_literal: true

class Components::Modal < Components::Base
  def initialize(id: "modal", closable: true)
    @id = id
    @closable = closable
  end

  def view_template(&block)
    div(
      id: @id,
      class: "fixed inset-0 z-50 flex items-center justify-center",
      data: { controller: "modal" }
    ) do
      # Backdrop
      div(
        class: "fixed inset-0 bg-black/50 transition-opacity",
        data: { action: "click->modal#close" }
      )

      # Modal content
      div(class: "relative z-10 w-full max-w-[80vw] max-h-[90vh] overflow-y-auto bg-background
                  rounded-lg shadow-xl mx-4 p-6") do
        if @closable
          button(
            class: "absolute top-4 right-4 text-muted-foreground hover:text-foreground cursor-pointer",
            data: { action: "click->modal#close" }
          ) { "✕" }
        end
        yield if block
      end
    end
  end
end
