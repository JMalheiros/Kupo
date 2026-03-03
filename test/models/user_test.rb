require "test_helper"

class UserTest < ActiveSupport::TestCase
  subject { build(:user) }

  context "validations" do
    should validate_presence_of(:email_address)
    should validate_uniqueness_of(:email_address).ignoring_case_sensitivity
    should have_secure_password
  end

  context "associations" do
    should have_many(:sessions).dependent(:destroy)
  end
end
