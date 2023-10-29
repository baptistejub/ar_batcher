# frozen_string_literal: true
require "rspec"
require "database_cleaner"
require "db-query-matchers"

require_relative "../lib/ar_batcher"
require_relative "helpers/db"
require_relative "helpers/models"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end

DBQueryMatchers.configure do |config|
  config.ignores = [/sqlite_master/, /table_info/, /transaction/]
end

TestHelper.setup_db!
