# frozen_string_literal: true

require_relative "batch_loader"
require_relative "builder"

module ArBatcher
  class Proxy
    attr_reader :config

    def initialize(config)
      @config = config
      @builders = nil
    end

    def batch_loader_builder_for(association_name)
      builders[association_name]
    end

    def batch_loader_for(scope, loader_scopes: {}, **options)
      ArBatcher::BatchLoader.new(scope, proxy: self, loader_scopes:, **options)
    end

    private

    def builders
      @builders ||= config.selected_reflections.transform_values { ArBatcher::Builder.new(_1) }
    end
  end
end
