# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe ArBatcher do
  it "has a version number" do
    expect(ArBatcher::VERSION).not_to be nil
  end

  context 'when included in a AR class' do
    let(:instance) { Post.new }

    it 'includes the instance methods' do
      expect(instance).to respond_to(:without_batch_loader)
      expect(instance).to respond_to(:batch_loader)
    end

    it 'extends the class methods' do
      expect(Post).to respond_to(:batch_loader_config)
      expect(Post).to respond_to(:to_batch_loader)
      expect(Post).to respond_to(:batch_loader_proxy)
    end
  end

  describe '#without_batch_loader' do
    let(:instance) { Post.new }
    subject { instance.without_batch_loader { instance.batch_loader } }

    context 'without a batch loader' do
      it { expect(subject).to be nil }
    end

    context 'with a batch loader' do
      before { instance.batch_loader = 'stuff' }

      it 'yields nothing inside the block' do
        expect(instance.batch_loader).not_to be nil
        expect(subject).to be nil
        expect(instance.batch_loader).not_to be nil
      end
    end

    context 'when looping on batch loaded records' do
      before do
        3.times do
          Post.create(user: User.create)
        end
      end

      subject { Post.all.to_batch_loader.to_a.each { |post| post.without_batch_loader { post.user.name } } }

      it 'makes a new query for each record' do
        # 1 "SELECT posts" + 3 * "SELECT user"
        expect { subject }.to make_database_queries(count: 4)
      end
    end
  end

  describe '.to_batch_loader' do
    subject { Post.all.to_batch_loader }

    context 'without any record' do
      it 'returns a batch loader without records' do
        expect { subject.to_a }.to make_database_queries(count: 1)
        expect { subject.to_a }.not_to make_database_queries
        expect(subject).to be_a(ArBatcher::BatchLoader)
        expect(subject.to_a).to be_empty
      end
    end

    context 'with some records' do
      before { 3.times { Post.create } }

      it 'returns the records' do
        expect { subject.to_a }.to make_database_queries(count: 1)
        expect { subject.to_a }.not_to make_database_queries
        expect(subject).to be_a(ArBatcher::BatchLoader)
        expect(subject.to_a.length).to eq(3)
      end
    end

    context 'when accessing a model not using the batch loader' do
      before { 3.times { Post.create.then { |post| post.exclude_batchers.create } } }

      it 'makes a query by record to load the association' do
        # 1 "SELECT posts" + 3 "SELECT exclude_batchers"
        expect { subject.to_a.each { |post| post.exclude_batchers.each(&:id) } }.to make_database_queries(count: 4)
        expect(subject.to_a.first.exclude_batchers.first).not_to respond_to(:batch_loader)
      end
    end
  end
end
