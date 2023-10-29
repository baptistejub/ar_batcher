# frozen_string_literal: true

require "active_record"

module TestHelper
  def self.setup_db!
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table, force: :cascade)
    end
    ActiveRecord::Schema.verbose = false

    ActiveRecord::Schema.define(version: 1) do
      create_table(:posts) do |t|
        t.belongs_to :user
        t.string :identifier
        t.string :name
        t.string :state
        t.boolean :category
        t.timestamps
      end

      create_table(:comments) do |t|
        t.belongs_to :post
        t.string :identifier
        t.string :name
        t.string :state
        t.text :message
        t.bigint :byte_size
        t.boolean :archived, null: false, default: false
        t.timestamps
      end

      create_table(:users) do |t|
        t.string :name
        t.timestamps
      end

      create_table(:audit_logs) do |t|
        t.references :record, polymorphic: true, null: false
        t.string :identifier
        t.string :level
        t.text :message
        t.timestamps
      end

      create_table(:exclude_batchers) do |t|
        t.belongs_to :post
        t.string :identifier
        t.timestamps
      end
    end
  end
end
