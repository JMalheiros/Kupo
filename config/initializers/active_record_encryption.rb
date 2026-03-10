# frozen_string_literal: true

Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", "dev-primary-key-do-not-use-in-prod")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", "dev-deterministic-key-not-for-prod")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", "dev-key-derivation-salt-not-prod")
