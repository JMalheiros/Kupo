require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  context "authentication required" do
    should "redirect index when not authenticated" do
      get categories_url
      assert_response :redirect
    end

    should "redirect create when not authenticated" do
      post categories_url, params: { category: { name: "Ruby" } }
      assert_response :redirect
    end

    should "redirect destroy when not authenticated" do
      category = create(:category)
      delete category_url(category)
      assert_response :redirect
    end
  end

  context "GET #index (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "list all categories" do
      category = create(:category, name: "Ruby")
      get categories_url
      assert_response :success
      assert_includes response.body, "Ruby"
    end
  end

  context "POST #create (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "create a category" do
      assert_difference("Category.count", 1) do
        post categories_url, params: { category: { name: "Ruby" } }
      end
      assert_redirected_to categories_url
    end

    should "not create category with blank name" do
      assert_no_difference("Category.count") do
        post categories_url, params: { category: { name: "" } }
      end
      assert_response :unprocessable_entity
    end
  end

  context "DELETE #destroy (authenticated)" do
    setup do
      @user = create(:user)
      sign_in(@user)
    end

    should "destroy a category" do
      category = create(:category)
      assert_difference("Category.count", -1) do
        delete category_url(category)
      end
      assert_redirected_to categories_url
    end
  end
end
