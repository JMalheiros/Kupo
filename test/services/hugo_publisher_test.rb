# frozen_string_literal: true

require "test_helper"

class HugoPublisherTest < ActiveSupport::TestCase
  should "raise NotConfiguredError when Hugo ENV vars are not configured" do
    article = create(:article, :publishing)

    assert_raises(HugoPublisher::NotConfiguredError) do
      HugoPublisher.new(article).call
    end
  end
end
