# frozen_string_literal: true

require_relative "ar_batcher/config"
require_relative "ar_batcher/proxy"
require_relative "ar_batcher/version"

module ArBatcher
  module ClassMethods
    def batch_loader_config
      @batch_loader_config ||= ArBatcher::Config.new(klass: self)
    end

    # For more boilerplate setup (only need to include the module in the AR class),
    # batch loader setup is done lazily on first invocation of the proxy,
    # normally after the class was fully loaded (when the associations are available).
    def batch_loader_proxy
      @batch_loader_proxy ||= ArBatcher::Proxy.new(batch_loader_config).tap do
        batch_loader_config.selected_reflections.each do |name, _|
          # Batch load the records and call the original implementation
          self.define_method(name) { batch_loader&.loader_for(name)&.load.then { super() } }
        end
      end
    end

    # Main entry point for the batch loader. To call on an AR scope.
    def to_batch_loader(association_scopes: {})
      batch_loader_proxy.batch_loader_for(current_scope, loader_scopes: association_scopes)
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  # Make the instance aware of the batch loader it was loaded from.
  attr_accessor :batch_loader

  # Disable batch loader and use AR default implementation for the duration of the block.
  # To use when batch loading isn't necessary.
  # Already loaded associations aren't cleared.
  def without_batch_loader
    loader, self.batch_loader = self.batch_loader, nil
    yield
  ensure
    self.batch_loader = loader
  end
end
