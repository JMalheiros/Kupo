# frozen_string_literal: true

module RubyUI
  class Combobox < Base
    def initialize(term: nil, create_url: nil, create_param: nil, **)
      @term = term
      @create_url = create_url
      @create_param = create_param
      super(**)
    end

    def view_template(&)
      div(**attrs, &)
    end

    private

    def default_attrs
      attrs = {
        role: "combobox",
        data: {
          controller: "ruby-ui--combobox",
          ruby_ui__combobox_term_value: @term,
          action: "turbo:morph@window->ruby-ui--combobox#updateTriggerContent"
        }
      }

      if @create_url
        attrs[:data][:ruby_ui__combobox_create_url_value] = @create_url
        attrs[:data][:ruby_ui__combobox_create_param_value] = @create_param
      end

      attrs
    end
  end
end
