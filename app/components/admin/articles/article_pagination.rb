# frozen_string_literal: true

class Components::Admin::Articles::ArticlePagination < Components::Base
  def initialize(current_page:, total_pages:, current_category: nil, current_status: nil, current_sort: nil)
    @current_page = current_page
    @total_pages = total_pages
    @current_category = current_category
    @current_status = current_status
    @current_sort = current_sort
  end

  def view_template
    Pagination(class: "mt-8") do
      PaginationContent do
        if @current_page > 1
          PaginationItem(href: page_path(1), data: { turbo_frame: "articles" }) do
            chevrons_left_icon
            plain "First"
          end
          PaginationItem(href: page_path(@current_page - 1), data: { turbo_frame: "articles" }) do
            chevron_left_icon
            plain "Prev"
          end
        end

        pagination_window.each do |page|
          if page == :ellipsis
            PaginationEllipsis()
          else
            PaginationItem(href: page_path(page), active: page == @current_page, data: { turbo_frame: "articles" }) do
              plain page.to_s
            end
          end
        end

        if @current_page < @total_pages
          PaginationItem(href: page_path(@current_page + 1), data: { turbo_frame: "articles" }) do
            plain "Next"
            chevron_right_icon
          end
          PaginationItem(href: page_path(@total_pages), data: { turbo_frame: "articles" }) do
            plain "Last"
            chevrons_right_icon
          end
        end
      end
    end
  end

  private

  def pagination_window
    if @total_pages <= 7
      (1..@total_pages).to_a
    else
      window = [ 1 ]
      window << :ellipsis if @current_page > 3
      range_start = [ @current_page - 1, 2 ].max
      range_end = [ @current_page + 1, @total_pages - 1 ].min
      window.concat((range_start..range_end).to_a)
      window << :ellipsis if @current_page < @total_pages - 2
      window << @total_pages
      window.uniq
    end
  end

  def page_path(page)
    params = {}
    params[:category] = @current_category if @current_category
    params[:status] = @current_status if @current_status
    params[:sort] = @current_sort if @current_sort.present? && @current_sort != "newest"
    params[:page] = page if page > 1
    root_path(**params)
  end

  def chevrons_left_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M11 7l-5 5l5 5")
      s.path(d: "M17 7l-5 5l5 5")
    end
  end

  def chevron_left_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M15 6l-6 6l6 6")
    end
  end

  def chevrons_right_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M7 7l5 5l-5 5")
      s.path(d: "M13 7l5 5l-5 5")
    end
  end

  def chevron_right_icon
    svg(xmlns: "http://www.w3.org/2000/svg", width: "24", height: "24", viewbox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor", fill: "none", stroke_linecap: "round", stroke_linejoin: "round", class: "h-4 w-4") do |s|
      s.path(stroke: "none", d: "M0 0h24v24H0z", fill: "none")
      s.path(d: "M9 6l6 6l-6 6")
    end
  end
end
