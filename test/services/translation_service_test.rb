require "test_helper"

class TranslationServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @article = create(:article, :draft, title: "Meu Artigo", body: "Este e um artigo sobre Ruby on Rails.")
  end

  should "return parsed translation with title and body" do
    fake_response = {
      "title" => "My Article",
      "body" => "This is an article about Ruby on Rails."
    }.to_json

    service = TranslationService.new(@user)
    service.define_singleton_method(:call_llm) { |_prompt| fake_response }

    result = service.translate(@article, language: "en")
    assert_equal "My Article", result["title"]
    assert_equal "This is an article about Ruby on Rails.", result["body"]
  end

  should "include target language name in the prompt" do
    captured_prompt = nil
    service = TranslationService.new(@user)
    service.define_singleton_method(:call_llm) { |prompt|
      captured_prompt = prompt
      { "title" => "t", "body" => "b" }.to_json
    }

    service.translate(@article, language: "pt-BR")
    assert_includes captured_prompt, "Brazilian Portuguese"
  end

  should "return nil on invalid JSON response" do
    service = TranslationService.new(@user)
    service.define_singleton_method(:call_llm) { |_prompt| "not valid json" }

    result = service.translate(@article, language: "en")
    assert_nil result
  end

  should "return nil when required keys are missing" do
    fake_response = { "other" => "data" }.to_json

    service = TranslationService.new(@user)
    service.define_singleton_method(:call_llm) { |_prompt| fake_response }

    result = service.translate(@article, language: "en")
    assert_nil result
  end
end
