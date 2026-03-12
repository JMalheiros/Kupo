# frozen_string_literal: true

module Articles
  class TranslationsController < ApplicationController
    def create
      @article = Article.find_by!(slug: params[:slug])
      language = params[:language]

      translation = @article.article_translations.find_or_initialize_by(language: language)
      translation.update!(status: "pending", title: nil, body: nil)

      TranslateArticleJob.perform_later(@article, Current.user, language)

      @article.reload
      render turbo_stream: turbo_stream.replace(
        "article-translation-editor",
        Components::Admin::Translations.new(article: @article)
      )
    end

    def update
      @article = Article.find_by!(slug: params[:slug])
      @categories = Category.all
      language = params[:language]

      translation = @article.article_translations.find_by!(language: language)
      translation.update!(translation_params)

      render Views::Admin::Articles::Form.new(article: @article, categories: @categories)
    end

    def export
      @article = Article.find_by!(slug: params[:slug])
      language = params[:language]
      translation = @article.article_translations.find_by!(language: language)

      markdown = "# #{translation.title}\n\n#{translation.body}"
      send_data markdown,
        filename: "#{@article.slug}-#{language}.md",
        type: "text/markdown",
        disposition: "attachment"
    end

    private

    def translation_params
      params.require(:article_translation).permit(:title, :body)
    end
  end
end
