# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_06_145427) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "api_key"
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id", null: false
    t.index ["user_id", "provider"], name: "index_api_keys_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "article_categories", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "category_id"], name: "index_article_categories_on_article_id_and_category_id", unique: true
    t.index ["article_id"], name: "index_article_categories_on_article_id"
    t.index ["category_id"], name: "index_article_categories_on_category_id"
  end

  create_table "article_reviews", force: :cascade do |t|
    t.integer "article_id", null: false
    t.string "content_status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.string "seo_status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_reviews_on_article_id", unique: true
  end

  create_table "article_translations", force: :cascade do |t|
    t.integer "article_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "language", default: "en", null: false
    t.string "status", default: "pending", null: false
    t.text "title"
    t.datetime "updated_at", null: false
    t.index ["article_id", "language"], name: "index_article_translations_on_article_id_and_language", unique: true
    t.index ["article_id"], name: "index_article_translations_on_article_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.text "plan"
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at"
    t.index ["status"], name: "index_articles_on_status"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "review_suggestions", force: :cascade do |t|
    t.integer "article_review_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "explanation", null: false
    t.text "original_text"
    t.string "process", null: false
    t.string "status", default: "pending", null: false
    t.text "suggested_text", null: false
    t.datetime "updated_at", null: false
    t.index ["article_review_id"], name: "index_review_suggestions_on_article_review_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.text "content_review_prompt", null: false
    t.datetime "created_at", null: false
    t.string "llm_model", default: "gemini-3-flash", null: false
    t.string "llm_provider", default: "gemini", null: false
    t.text "seo_review_prompt", null: false
    t.text "translation_prompt", default: "You are a professional translator. Translate the following article accurately and naturally.", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_keys", "users"
  add_foreign_key "article_categories", "articles"
  add_foreign_key "article_categories", "categories"
  add_foreign_key "article_reviews", "articles"
  add_foreign_key "article_translations", "articles"
  add_foreign_key "review_suggestions", "article_reviews"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "users"
end
