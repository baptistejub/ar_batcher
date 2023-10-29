# frozen_string_literal: true

require "active_record"

require_relative "polymorphic_batch_loader"

module ArBatcher
  class Builder
    def initialize(reflection)
      @reflection = reflection
    end

    def call(records, scopes)
      sym_name = @reflection.name.to_sym
      options = { loader_scopes: scopes.fetch("#{@reflection.name}_scopes".to_sym, {}) }

      ActiveRecord::Associations::Preloader.new(
        records:,
        associations: sym_name,
        scope: scopes[sym_name]
      ).then do |preloader|
        if @reflection.polymorphic?
          ArBatcher::PolymorphicBatchLoader.new(preloader, **options)
        else
          @reflection.klass.batch_loader_proxy.batch_loader_for(preloader, **options)
        end
      end
    end
  end
end
