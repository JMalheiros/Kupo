class CategoriesController < ApplicationController
  def index
    @categories = Category.all
    render Views::Admin::Categories::Index.new(categories: @categories)
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to categories_url
    else
      @categories = Category.all
      render Views::Admin::Categories::Index.new(categories: @categories, new_category: @category), status: :unprocessable_entity
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy!
    redirect_to categories_url
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
