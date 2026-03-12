require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  should belong_to(:user)

  should validate_presence_of(:provider)
  should validate_inclusion_of(:provider).in_array(ApiKey::PROVIDERS)
  context "api_key validation" do
    should "require api_key for non-ollama providers" do
      api_key = build(:api_key, provider: "gemini", api_key: nil)
      assert_not api_key.valid?
      assert_includes api_key.errors[:api_key], "can't be blank"
    end

    should "not require api_key for ollama" do
      api_key = build(:api_key, provider: "ollama", api_key: nil, url: "http://localhost:11434")
      assert api_key.valid?
    end
  end

  context "url validation" do
    should "require url for ollama" do
      api_key = build(:api_key, provider: "ollama", api_key: nil, url: nil)
      assert_not api_key.valid?
      assert_includes api_key.errors[:url], "can't be blank"
    end

    should "not require url for non-ollama providers" do
      api_key = build(:api_key, provider: "gemini", url: nil)
      assert api_key.valid?
    end
  end

  should "enforce one key per provider per user" do
    user = create(:user)
    create(:api_key, user: user, provider: "gemini")

    duplicate = build(:api_key, user: user, provider: "gemini")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider], "has already been taken"
  end

  should "allow different providers for the same user" do
    user = create(:user)
    create(:api_key, user: user, provider: "gemini")

    other = build(:api_key, user: user, provider: "claude")
    assert other.valid?
  end

  should "allow same provider for different users" do
    create(:api_key, provider: "gemini")

    other = build(:api_key, provider: "gemini")
    assert other.valid?
  end

  should "encrypt the api_key attribute" do
    api_key = create(:api_key, api_key: "sk-secret-123")
    raw_value = ApiKey.connection.select_value(
      "SELECT api_key FROM api_keys WHERE id = #{api_key.id}"
    )

    assert_not_equal "sk-secret-123", raw_value
    assert_equal "sk-secret-123", api_key.reload.api_key
  end
end
