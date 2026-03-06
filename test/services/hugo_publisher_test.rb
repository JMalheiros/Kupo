# frozen_string_literal: true

require "test_helper"

class HugoPublisherTest < ActiveSupport::TestCase
  should "skip publishing when Hugo ENV vars are not configured" do
    article = create(:article, :publishing)

    # With no ENV vars set, call should return nil (no-op)
    assert_nil HugoPublisher.new(article).call
  end
end
