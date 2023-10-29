# frozen_string_literal: true

module ArBatcher
  class Config
    attr_accessor :associations
    attr_reader :klass

    def initialize(klass:)
      @klass = klass
      @reflections = nil
    end

    # Use only selected reflections: the ones explicitly set or all associations that include ArBatcher or that are polymorphic
    # (ArBatcher inclusion can't be checked with polymorphic associations, so assuming they're selected).
    def selected_reflections
      @reflections ||= (associations ? klass.reflections.select { |name, _| associations.include?(name.to_sym) } : klass.reflections).then do
        _1.select { |_, r| r.polymorphic? || r.klass.include?(ArBatcher) }
      end
    end
  end
end
