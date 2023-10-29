# frozen_string_literal: true

require "active_record"

module ArBatcher
  class BatchLoader
    class PreloaderHandler
      def initialize(preloader)
        @preloader = preloader
        @loader = nil
      end

      def records
        loader.preloaded_records
      end

      private

      def loader
        @loader ||= @preloader.call.first
      end
    end

    class EnumeratorHandler
      def initialize(enumerator)
        @enumerator = enumerator
      end

      def records = @enumerator
    end

    def initialize(data, proxy:, loader_scopes: {})
      @handler =
        if data.is_a?(ActiveRecord::Associations::Preloader)
          PreloaderHandler.new(data)
        else
          EnumeratorHandler.new(data)
        end

      @proxy = proxy
      @loader_scopes = loader_scopes
      @loaders = {}
      @records = nil
    end

    def records
      # Assign the batch loader to the records to be able to follow the association tree with batch loading.
      # ActiveRecord associates the loaded records to their parents.
      @records ||= @handler.records.each { _1.batch_loader = self }
    end

    def load = records
    def to_a = records

    def loader_for(assoc_name)
      @loaders[assoc_name] ||= @proxy.batch_loader_builder_for(assoc_name).call(records, @loader_scopes)
    end

    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)}>"
    end
  end
end
