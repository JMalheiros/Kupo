class AddUniqueIndexToArticleReviews < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate reviews, keeping the latest per article.
    # Must delete dependent review_suggestions first due to FK constraint,
    # then delete the duplicate article_reviews.
    execute <<~SQL
      DELETE FROM review_suggestions
      WHERE article_review_id IN (
        SELECT id FROM article_reviews
        WHERE id NOT IN (
          SELECT MAX(id) FROM article_reviews GROUP BY article_id
        )
      )
    SQL

    execute <<~SQL
      DELETE FROM article_reviews
      WHERE id NOT IN (
        SELECT MAX(id) FROM article_reviews GROUP BY article_id
      )
    SQL

    remove_index :article_reviews, :article_id
    add_index :article_reviews, :article_id, unique: true
  end

  def down
    remove_index :article_reviews, :article_id, unique: true
    add_index :article_reviews, :article_id
  end
end
