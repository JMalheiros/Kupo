class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :setting, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  accepts_nested_attributes_for :api_keys, reject_if: ->(attrs) { attrs["api_key"].blank? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
