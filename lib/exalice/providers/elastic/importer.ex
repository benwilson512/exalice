defmodule ExAlice.Geocoder.Providers.Elastic.Importer do

  import Tirexs.Mapping
  import Tirexs.Index.Settings

  require Tirexs.ElasticSearch

  def import(file \\ false) do
    unless is_binary(file) do
      file = ExAlice.Geocoder.config(:file)
    end

    index_name = ExAlice.Geocoder.config(:index)
    doc_type = ExAlice.Geocoder.config(:doc_type)

    bootstrap_index(index_name, doc_type)

    IO.puts "Importing...  #{file}"

    chunk_number = ExAlice.Geocoder.config(:chunks)

    read_file(file)
    |> chunk(chunk_number)
    |> Enum.map(fn chunk -> enqueue(chunk) end)
  end

  def bootstrap_index(index_name, doc_type) do
    index = [index: index_name, type: doc_type]
    settings = Tirexs.ElasticSearch.config()

    settings do
      analysis do
        analyzer "autocomplete_analyzer",
          [
            filter: ["icu_normalizer", "icu_folding", "edge_ngram"],
            tokenizer: "icu_tokenizer"
          ]
        filter "edge_ngram", [type: "edgeNGram", min_gram: 1, max_gram: 15]
      end
    end

    mappings do
      indexes "country", type: "string"
      indexes "city", type: "string"
      indexes "suburb", type: "string"
      indexes "road", type: "string"
      indexes "postcode", type: "string", index: "not_analyzed"
      indexes "housenumber", type: "string", index: "not_analyzed"
      indexes "coordinates", type: "geo_point"
      indexes "full_address", type: "string"
      indexes "_all", [enabled: "true"]
      indexes "_ttl", [enabled: "true"]
    end

    Tirexs.ElasticSearch.put(index_name, JSX.encode!(index), settings)
  end

  def read_file(file) do
    File.stream!(file)
    |> Stream.map(fn content -> String.split(content, "\n", trim: true) end)
  end

  def chunk(data, chunk_number) do
    Stream.chunk(data, chunk_number, chunk_number, [])
  end

  def enqueue(chunk) do
    Toniq.enqueue(IndexerWorker, %{chunk: chunk})
  end
end
