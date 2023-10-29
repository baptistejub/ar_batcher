# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe ArBatcher::Config do
  subject { described_class.new(klass: Post) }

  context 'without any excluded associations' do
    it 'registers all the associations' do
      expect(subject.selected_reflections).to eq(Post.reflections.except('exclude_batchers'))
    end
  end

  context 'without some excluded associations' do
    before { subject.associations = [:comments] }

    it 'keeps only the selected associations' do
      expect(subject.selected_reflections.keys).to eq(['comments'])
    end
  end
end
