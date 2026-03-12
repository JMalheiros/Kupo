require "test_helper"

class SettingTest < ActiveSupport::TestCase
  should belong_to(:user)

  should validate_presence_of(:llm_provider)
  should validate_inclusion_of(:llm_provider).in_array(%w[gemini claude openai ollama])
  should validate_presence_of(:llm_model)

  context ".for" do
    should "create a setting with defaults when none exists" do
      user = create(:user)

      setting = Setting.for(user)

      assert setting.persisted?
      assert_equal "gemini", setting.llm_provider
      assert_equal "gemini-2.5-flash", setting.llm_model
      assert_includes setting.plan_prompt, "content strategist"
      assert_includes setting.content_review_prompt, "expert editor"
      assert_includes setting.seo_review_prompt, "SEO"
    end

    should "return existing setting" do
      user = create(:user)
      existing = Setting.for(user)

      assert_equal existing, Setting.for(user)
      assert_equal 1, Setting.where(user: user).count
    end
  end

  context ".for_edit" do
    should "build missing api keys for the user" do
      user = create(:user)

      Setting.for_edit(user)

      providers = user.api_keys.map(&:provider).sort
      assert_equal %w[claude gemini ollama openai], providers
      assert user.api_keys.all?(&:new_record?)
    end

    should "not duplicate existing api keys" do
      user = create(:user)
      create(:api_key, user: user, provider: "gemini")

      Setting.for_edit(user)

      built_providers = user.api_keys.select(&:new_record?).map(&:provider).sort
      assert_equal %w[claude ollama openai], built_providers
    end
  end
end
