require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  context "GET /settings/edit" do
    should "render the settings form" do
      get edit_settings_url

      assert_response :success
    end

    should "create a setting record if none exists" do
      assert_nil @user.reload.setting

      get edit_settings_url

      assert_not_nil @user.reload.setting
    end
  end

  context "PATCH /settings" do
    should "update setting attributes" do
      Setting.for(@user)

      patch settings_url, params: {
        setting: { llm_provider: "claude", llm_model: "claude-sonnet-4-20250514" },
        user: { api_keys_attributes: {} }
      }

      assert_redirected_to root_url
      @user.setting.reload
      assert_equal "claude", @user.setting.llm_provider
      assert_equal "claude-sonnet-4-20250514", @user.setting.llm_model
    end

    should "create api keys for the user" do
      Setting.for(@user)

      patch settings_url, params: {
        setting: { llm_provider: "gemini", llm_model: "gemini-3-flash" },
        user: { api_keys_attributes: {
          "0" => { provider: "gemini", api_key: "test-gemini-key" },
          "1" => { provider: "claude", api_key: "test-claude-key" }
        } }
      }

      assert_redirected_to root_url
      assert_equal 2, @user.api_keys.count
      assert_equal "test-gemini-key", @user.api_keys.find_by(provider: "gemini").api_key
    end

    should "skip api keys with blank values" do
      Setting.for(@user)

      patch settings_url, params: {
        setting: { llm_provider: "gemini", llm_model: "gemini-3-flash" },
        user: { api_keys_attributes: {
          "0" => { provider: "gemini", api_key: "test-key" },
          "1" => { provider: "claude", api_key: "" }
        } }
      }

      assert_redirected_to root_url
      assert_equal 1, @user.api_keys.count
    end

    should "update existing api keys" do
      Setting.for(@user)
      api_key = create(:api_key, user: @user, provider: "gemini", api_key: "old-key")

      patch settings_url, params: {
        setting: { llm_provider: "gemini", llm_model: "gemini-3-flash" },
        user: { api_keys_attributes: {
          "0" => { id: api_key.id, provider: "gemini", api_key: "new-key" }
        } }
      }

      assert_redirected_to root_url
      assert_equal "new-key", api_key.reload.api_key
    end
  end
end
