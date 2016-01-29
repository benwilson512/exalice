defmodule IndexerWorker do
  use Toniq.Worker, max_concurrency: 4

  alias ExAlice.Geocoder.Providers.Elastic.Indexer

  def perform(%{chunk: chunk}) do
    Indexer.index(chunk)   
  end
end
