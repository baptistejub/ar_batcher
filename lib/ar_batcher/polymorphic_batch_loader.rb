# frozen_string_literal: true

require_relative "batch_loader"

module ArBatcher
  class PolymorphicBatchLoader < BatchLoader
    def initialize(preloader, loader_scopes: {})
      @preloader = preloader
      @loader_scopes = loader_scopes
      @records = nil
    end

    def records
      # Polymorphic association have several record types that can't be known in advance,
      # thus we have load the records to determine the right batch loader to assign to them
      # (to allow proper chaining of batch loaders).
      @records ||= @preloader.call.flat_map do |loader|
        loader.preloaded_records.compact.then do |recs|
          next [] if recs.empty?

          klass = recs.first.class

          if klass.include?(ArBatcher)
            loader = klass.batch_loader_proxy.batch_loader_for(recs, loader_scopes: @loader_scopes)

            recs.each { _1.batch_loader = loader }
          else
            recs
          end
        end
      end
    end

    def loader_for(*) = nil
  end
end
