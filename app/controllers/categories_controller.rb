class CategoriesController < ApplicationController
  def index
    render Views::Admin::Categories::Index.new(categories: categories)
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      streams = [ turbo_stream.append("categories-list", partial: "categories/category_row", locals: { category: @category }) ]
      streams << turbo_stream.append("category-combobox-list", partial: "categories/combobox_item", locals: { category: @category }) if combobox_request?

      render turbo_stream: streams
    else
      render Views::Admin::Categories::Index.new(categories: categories, new_category: @category), status: :unprocessable_entity
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy!

    render turbo_stream: turbo_stream.remove("category_#{@category.id}")
  end

  private

  def categories
    @categories ||= Category.all
  end

  def category_params
    params.require(:category).permit(:name)
  end

  def combobox_request?
    request.headers["X-Combobox-Create"].present?
  end
end
