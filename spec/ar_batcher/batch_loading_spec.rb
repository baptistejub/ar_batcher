# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe 'batch loading' do
  subject { Post.all.to_batch_loader }

  describe 'belongs_to' do
    before do
      3.times do
        Post.create(user: User.create)
      end
    end

    it 'makes one query by model' do
      expect { subject.to_a }.to make_database_queries(count: 1)
      expect { subject.to_a }.not_to make_database_queries
      expect(subject.to_a.length).to eq(3)

      expect { subject.to_a.map(&:user) }.to make_database_queries(count: 1)
      expect { subject.to_a.map(&:user) }.not_to make_database_queries
      expect(subject.to_a.map(&:user).length).to eq(3)
      expect(subject.to_a.map(&:user)).to all(be_a(User))
      expect(subject.to_a.map(&:user).map(&:batch_loader)).to all(be_a(ArBatcher::BatchLoader))
    end
  end

  describe 'has_many' do
    before do
      3.times do
        Post.create.then { |p| 2.times { p.comments.create } }
      end
    end

    it 'makes one query by model' do
      expect { subject.to_a }.to make_database_queries(count: 1)
      expect { subject.to_a }.not_to make_database_queries
      expect(subject.to_a.length).to eq(3)

      expect { subject.to_a.flat_map(&:comments) }.to make_database_queries(count: 1)
      expect { subject.to_a.flat_map(&:comments) }.not_to make_database_queries
      expect(subject.to_a.flat_map(&:comments).length).to eq(6)
      expect(subject.to_a.flat_map(&:comments)).to all(be_a(Comment))
      expect(subject.to_a.flat_map(&:comments).map(&:batch_loader)).to all(be_a(ArBatcher::BatchLoader))
    end
  end

  describe 'has_many through' do
    before do
      3.times do
        User.create.then { |u| Post.create(user: u).then { |p| p.comments.create } }
      end
    end

    subject { User.all.to_batch_loader }

    it 'makes one query by model' do
      expect { subject.to_a }.to make_database_queries(count: 1)
      expect { subject.to_a }.not_to make_database_queries
      expect(subject.to_a.length).to eq(3)

      expect { subject.to_a.flat_map(&:comments) }.to make_database_queries(count: 2)
      expect { subject.to_a.flat_map(&:comments) }.not_to make_database_queries
      expect(subject.to_a.flat_map(&:comments).length).to eq(3)
      expect(subject.to_a.flat_map(&:comments)).to all(be_a(Comment))
      expect(subject.to_a.flat_map(&:comments).map(&:batch_loader)).to all(be_a(ArBatcher::BatchLoader))
    end
  end

  describe 'has_one' do
    before do
      3.times do
        Post.create.then(&:create_audit_log)
      end
    end

    it 'makes one query by model' do
      expect { subject.to_a }.to make_database_queries(count: 1)
      expect { subject.to_a }.not_to make_database_queries
      expect(subject.to_a.length).to eq(3)

      expect { subject.to_a.map(&:audit_log) }.to make_database_queries(count: 1)
      expect { subject.to_a.map(&:audit_log) }.not_to make_database_queries
      expect(subject.to_a.map(&:audit_log).length).to eq(3)
      expect(subject.to_a.map(&:audit_log)).to all(be_a(AuditLog))
      expect(subject.to_a.map(&:audit_log).map(&:batch_loader)).to all(be_a(ArBatcher::BatchLoader))
    end
  end

  describe 'polymorphic' do
    before do
      3.times do
        AuditLog.create(record: Post.create)
        AuditLog.create(record: User.create)
      end
    end

    subject { AuditLog.all.to_batch_loader }

    it 'makes one query by model' do
      expect { subject.to_a }.to make_database_queries(count: 1)
      expect { subject.to_a }.not_to make_database_queries
      expect(subject.to_a.length).to eq(6)

      # One query by record class (Post and User)
      expect { subject.to_a.map(&:record) }.to make_database_queries(count: 2)
      expect { subject.to_a.map(&:record) }.not_to make_database_queries
      expect(subject.to_a.map(&:record).length).to eq(6)
      records = subject.to_a.map(&:record).group_by(&:class)
      expect(records[Post].length).to eq(3)
      expect(records[User].length).to eq(3)
      expect(subject.to_a.map(&:record).map(&:batch_loader)).to all(be_a(ArBatcher::BatchLoader))
    end
  end

  describe 'nested associations' do
    before do
      3.times do
        User.create.then do |user|
          Post.create(user:).then { |post| 2.times { post.comments.create } }
        end
      end
    end

    subject { User.all.to_batch_loader }

    it 'makes one query by model' do
      # SELECT users
      # SELECT posts
      # SELECT comments
      expect do
        subject.to_a.each { |user| user.posts.each { |post| post.comments.each(&:message) } }
      end.to make_database_queries(count: 3)

      expect(subject.to_a.length).to eq(3)

      expect do
        subject.to_a.each { |user| user.posts.each { |post| post.comments.each(&:message) } }
      end.not_to make_database_queries
    end
  end

  describe 'integrity checks' do
    let!(:user1) { User.create }
    let!(:user2) { User.create }

    let!(:post1) { Post.create(user: user1) }
    let!(:post2) { Post.create(user: user1) }
    let!(:post3) { Post.create(user: user2) }

    let!(:comment1) { post1.comments.create }
    let!(:comment2) { post3.comments.create }
    let!(:comment3) { post3.comments.create }

    let!(:audit_log1) { post2.create_audit_log }
    let!(:audit_log2) { post3.create_audit_log }
    let!(:audit_log3) { user2.create_audit_log }

    subject { User.all.to_batch_loader.to_a.sort_by(&:id) }

    it 'makes the right associations' do
      expect(subject.length).to eq(2)
      expect(subject[0]).to eq(user1)
      expect(subject[0].posts.sort_by(&:id)).to eq([post1, post2])
      expect(subject[0].audit_log).to be_nil
      expect(subject[0].posts.sort_by(&:id).map(&:comments)).to eq([[comment1], []])
      expect(subject[0].posts.sort_by(&:id).map(&:audit_log)).to eq([nil, audit_log1])

      expect(subject[1]).to eq(user2)
      expect(subject[1].posts).to eq([post3])
      expect(subject[1].audit_log).to eq(audit_log3)
      expect(subject[1].posts.map(&:comments)).to eq([[comment2, comment3]])
      expect(subject[1].posts.map(&:audit_log)).to eq([audit_log2])
    end
  end

  describe 'custom scoping' do
    before do
      3.times do
        User.create.then do |user|
          Post.create(user:).then { |post| 2.times { |i| post.comments.create(state: (i == 0 ? 'active' : 'inactive')) } }
        end
      end
    end

    subject do
      User.all.select(:id).to_batch_loader(
        association_scopes: {
          posts: Post.select(:id, :identifier, :user_id),
          posts_scopes: { comments: Comment.where(state: 'active').select(:id, :state, :post_id) }
        }
      )
    end

    it 'respects the given scopes' do
      expect(subject.to_a.length).to eq(3)
      expect(subject.to_a[0].attributes.keys).to eq(['id'])
      expect(subject.to_a[0].posts.first.attributes.keys).to eq(['id', 'identifier', 'user_id'])
      expect(subject.to_a[0].posts.first.comments.map(&:state)).to eq(['active'])
      expect(subject.to_a[0].posts.first.comments.first.attributes.keys).to eq(['id', 'state', 'post_id'])
    end
  end
end
