# frozen_string_literal: true

class Post < ActiveRecord::Base
  include ::ArBatcher

  has_many :comments
  belongs_to :user
  has_one :audit_log, as: :record
  has_many :exclude_batchers
end

class Comment < ActiveRecord::Base
  include ::ArBatcher

  belongs_to :post

  serialize :message, coder: JSON
end

class User < ActiveRecord::Base
  include ::ArBatcher

  has_many :posts
  has_many :comments, through: :posts
  has_one :audit_log, as: :record
end

class AuditLog < ActiveRecord::Base
  include ::ArBatcher

  belongs_to :record, polymorphic: true
end

class ExcludeBatcher < ActiveRecord::Base
  belongs_to :post
end
