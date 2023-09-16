# frozen_string_literal: true

require "active_support/testing/strict_warnings"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "bin/test"

# Disable available locale checks to allow to add locale after initialized.
I18n.enforce_available_locales = false

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

class ActiveSupport::TestCase
  module QueryHelpers
    include ActiveJob::TestHelper

    def assert_queries(expected_count, &block)
      ActiveRecord::Base.connection.materialize_transactions

      queries = []
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries << payload[:sql] unless %w[ SCHEMA TRANSACTION ].include?(payload[:name])
      end

      result = _assert_nothing_raised_or_warn("assert_queries", &block)
      assert_equal expected_count, queries.size, "#{queries.size} instead of #{expected_count} queries were executed. #{queries.inspect}"
      result
    end

    def assert_no_queries(&block)
      assert_queries(0, &block)
    end
  end

  private
    def create_file_blob(filename:, content_type:, metadata: nil)
      ActiveStorage::Blob.create_and_upload! io: file_fixture(filename).open, filename: filename, content_type: content_type, metadata: metadata
    end
end

# Encryption
ActiveRecord::Encryption.configure \
  primary_key: "test master key",
  deterministic_key: "test deterministic key",
  key_derivation_salt: "testing key derivation salt",
  support_unencrypted_data: true

require_relative "../../tools/test_common"
