# frozen_string_literal: true

require "test_helper"

class LangchainClientTest < ActiveSupport::TestCase
  context ".gemini" do
    should "build a GoogleGemini client with default model" do
      ENV.stubs(:fetch).with("GEMINI_API_KEY").returns("test-key")
      Langchain::LLM::GoogleGemini.expects(:new).with(
        api_key: "test-key",
        default_options: { chat_model: "gemini-2.5-flash" }
      ).returns(:llm_instance)

      result = LangchainClient.gemini

      assert_equal :llm_instance, result
    end

    should "build a GoogleGemini client with custom model" do
      ENV.stubs(:fetch).with("GEMINI_API_KEY").returns("test-key")
      Langchain::LLM::GoogleGemini.expects(:new).with(
        api_key: "test-key",
        default_options: { chat_model: "gemini-2.5-pro" }
      ).returns(:llm_instance)

      result = LangchainClient.gemini(model: "gemini-2.5-pro")

      assert_equal :llm_instance, result
    end
  end

  context ".claude" do
    should "build an Anthropic client with default model" do
      ENV.stubs(:fetch).with("ANTHROPIC_API_KEY").returns("test-key")
      Langchain::LLM::Anthropic.expects(:new).with(
        api_key: "test-key",
        default_options: { chat_model: "claude-sonnet-4-20250514" }
      ).returns(:llm_instance)

      result = LangchainClient.claude

      assert_equal :llm_instance, result
    end
  end

  context ".openai" do
    should "build an OpenAI client with default model" do
      ENV.stubs(:fetch).with("OPENAI_API_KEY").returns("test-key")
      Langchain::LLM::OpenAI.expects(:new).with(
        api_key: "test-key",
        default_options: { chat_model: "gpt-4o-mini" }
      ).returns(:llm_instance)

      result = LangchainClient.openai

      assert_equal :llm_instance, result
    end
  end

  context ".for_user" do
    should "build client from user settings" do
      user = create(:user)
      setting = Setting.for(user)
      setting.update!(llm_provider: "gemini", llm_model: "gemini-2.5-flash")

      ENV.stubs(:fetch).with("GEMINI_API_KEY").returns("env-key")
      Langchain::LLM::GoogleGemini.expects(:new).with(
        api_key: "env-key",
        default_options: { chat_model: "gemini-2.5-flash" }
      ).returns(:llm_instance)

      result = LangchainClient.for_user(user)

      assert_equal :llm_instance, result
    end

    should "prefer user api key over env var" do
      user = create(:user)
      Setting.for(user).update!(llm_provider: "gemini", llm_model: "gemini-2.5-flash")
      create(:api_key, user: user, provider: "gemini", api_key: "user-key")

      Langchain::LLM::GoogleGemini.expects(:new).with(
        api_key: "user-key",
        default_options: { chat_model: "gemini-2.5-flash" }
      ).returns(:llm_instance)

      result = LangchainClient.for_user(user.reload)

      assert_equal :llm_instance, result
    end

    should "fall back to env var when user has no api key for provider" do
      user = create(:user)
      Setting.for(user).update!(llm_provider: "claude", llm_model: "claude-sonnet-4-20250514")

      ENV.stubs(:fetch).with("ANTHROPIC_API_KEY").returns("env-key")
      Langchain::LLM::Anthropic.expects(:new).with(
        api_key: "env-key",
        default_options: { chat_model: "claude-sonnet-4-20250514" }
      ).returns(:llm_instance)

      result = LangchainClient.for_user(user)

      assert_equal :llm_instance, result
    end
  end

  context "with unknown provider" do
    should "raise KeyError" do
      assert_raises(KeyError) do
        LangchainClient.send(:build, "unknown_provider")
      end
    end
  end
end
