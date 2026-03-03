require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    @category = create(:category, name: "Ruby")
    @published = create(:article, :published, title: "Published Article", categories: [ @category ])
    @draft = create(:article, :draft, title: "Draft Article")
  end

  test "visitor sees published articles" do
    visit root_url
    assert_text "Published Article"
    assert_no_text "Draft Article"
  end

  test "visitor can filter by category" do
    create(:article, :published, title: "Untagged Article")
    visit root_url
    click_on "Ruby"
    assert_text "Published Article"
    assert_no_text "Untagged Article"
  end

  test "visitor can view article in modal" do
    visit root_url
    click_on "Published Article"
    assert_selector "[data-controller='modal']"
    assert_text "Published Article"
  end

  test "admin sees all articles and admin controls after sign in" do
    sign_in_as(@user)
    assert_text "Sign out"
    assert_text "Published Article"
    assert_text "Draft Article"
    assert_text "New Article"
    assert_text "Manage Categories"
  end

  private

  def sign_in_as(user)
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password123"
    click_button "Sign in"
  end
end
