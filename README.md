# ArBatcher

An easy-to-use ActiveRecord batch loader to prevent N+1 database queries.

## Why use it?
ActiveRecord offers the `includes` method to eager load associations. It requires to know the needed associations to load beforehand, which isn't very practical in some situations (for example with GraphQL). It also loads the full records, even when only a few attributes are needed.

This gem waits for the first actual access to the association to load the associated records using a single query. It also allows to customize the attributes to select from the database.

In a nutshell:
- **Easy to use**: no need to know what records are actually required when building the query, they are lazy loaded on demand (only if necessary). Nothing to change in your ActiveRecord models, just call the batch loader and iterate normally over the records and their associations.
- **Flexible**: per-request scoping on associations, allowing to select only some fields (better for performance)
- **Minimal and simple**: Doesn't patch ActiveRecord, only the model association accessors.

## Installation

Add this line to your application Gemfile:
```
gem 'ar_batcher', git: 'https://github.com/baptistejub/ar_batcher'
```

## Usage

Include the module in your ActiveRecord models:
```ruby
class Post < ApplicationRecord
  include ArBatcher
  # [...]
end


# Or if you want to use it globally, include the module in ApplicationRecord:
class ApplicationRecord < ActiveRecord::Base
  include ArBatcher

  self.abstract_class = true
end
```

Optionally, you can restrict the associations that can be batch loaded (by default all associations are included):
```ruby
class Book < ApplicationRecord
  include ArBatcher

  has_many :pages
  has_many :chapters
  # [...]

  # Only batch loading the :pages association
  # Note: ensure to set the associations before calling the batch loader (values are cached and can't be modified afterwards)
  batch_loader_config.associations = [:pages]
end
```

Call `.to_batch_loader` on any ActiveRecord scope and iterate normally over the records:
```ruby
Post.where(state: 'active').limit(100).to_batch_loader.to_a.each do |post|
  # From there, all the "batch loadable" associations are loaded on demand using the batch loader.
  puts post.id

  # No N+1, all comments are loaded in a single query
  post.comments.map(&:name)

  # Makes 1 query to load all post users + 1 query to load all the user's comments
  post.user.comments.map(&:name)

  # Disable the batch loader for the duration of the block.
  # This makes 1 query by post.
  post.with_batch_loader { post.audit_log }
end
```

You can also customize the association scopes on a per-query basis:
```ruby
User.all.select(:id).to_batch_loader(
  association_scopes: {
    posts: Post.select(:id, :identifier, :user_id),
    # Use `#{association_name}_scopes` key to target nested scopes
    posts_scopes: { comments: Comment.where(state: 'active').select(:id, :state, :post_id) }
  }
).to_a.each do |user|
  # Only load the select fields: #<User id: 1>
  puts user.id

  # raises `ActiveModel::MissingAttributeError: missing attribute 'name' for User`
  puts user.name

  # [#<Post id: 1, identifier: 'test', user_id: 1>, ...]
  # Be sure that :user_id is selected for the query, else `posts` will be empty.
  user.posts.map(&:identifier)

  # Loads only the "active" post
  # [#<Comment id: 1, state: "active", post_id: 1>]
  user.posts.first.comments.map(&:name)

  # WARNING: this kind of action makes an extra query and ignores the custom scopes.
  #   This counts all the post comments, not the active ones.
  user.post.first.comments.count
end
```

**WARNING**: be careful and sure of what you're doing before modifying the scopes. Otherwise it could cause unexpected results (for example returning empty set of associated records if some required fields are omitted - like `Post#user_id`).

### How it works
Upon inclusion in a model, it adds a `batch_loader` attribute accessor and patches the association accessor methods.

When loading records with `scope.to_batch_loader`, it assigns the batch loader instance to each record, in #batch_loader accessor, making the record aware of the batch loader it was loaded from.
The batch loader instance holds the knowledge of the scopes and already loaded records, allowing it to build the appropriate queries to load all association records in a single query, using vanilla ActiveRecord.

When an association accessor is called on a batch loaded record for the first time, the batch loader instance from its #batch_loader accessor fetches once all the associated records and assigns them to their parents. Subsequent accesses use the already loaded records (using vanilla ActiveRecord caching for associations).
The batch loader instance is recursively shared to all records loaded from it, allowing any nested association to also call it.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/baptistejub/ar_batcher.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
