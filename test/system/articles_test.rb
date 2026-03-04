require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, title: "Published Article", categories: [ @category ])
    @draft = create(:article, :draft, title: "Draft Article")
  end

  test "unauthenticated user is redirected to login" do
    visit root_url
    assert_current_path new_session_path
  end

  test "authenticated user sees all articles with admin controls" do
    sign_in_as(@user)
    assert_text "Published Article"
    assert_text "Draft Article"
    assert_text "New Article"
    assert_text "Manage Categories"
  end

  test "authenticated user can filter by category" do
    create(:article, :published, title: "Untagged Article")
    sign_in_as(@user)
    click_on "Ruby"
    assert_text "Published Article"
    assert_no_text "Untagged Article"
  end

  test "authenticated user can preview an article" do
    sign_in_as(@user)
    assert_text "Articles" # Wait for index to load after sign in
    visit preview_article_path(slug: @published.slug)
    assert_text @published.title
    assert_text "Export Markdown"
  end

  private

  def sign_in_as(user)
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end
