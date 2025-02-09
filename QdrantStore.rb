require "qdrant"

class QdrantStore
  VECTOR_SIZE = 1024

  def initialize(collection_name)
    @collection_name = collection_name
    @client = Qdrant::Client.new(
      url: "http://localhost:6333",
      api_key: nil # Add API key if using authentication
    )
    ensure_collection_exists
  end

  def store_embeddings(chunks, embeddings, url)
    raise "Number of chunks and embeddings must match" unless chunks.length == embeddings.length

    points = chunks.zip(embeddings).map.with_index do |(chunk, embedding), id|
      {
        id: id,
        vector: embedding,
        payload: {
          content: chunk,
          url: url
        }
      }
    end

    @client.points.upsert(
      collection_name: @collection_name,
      points: points
    )
  end

  private

  def ensure_collection_exists
    response = @client.collections.list
    existing_collections = response.dig("result", "collections")
    return if existing_collections&.any? { |c| c["name"] == @collection_name }

    puts "Creating collection #{@collection_name}..."
    @client.collections.create(
      collection_name: @collection_name,
      vectors: {
        size: VECTOR_SIZE,
        distance: "Cosine"
      }
    )
    puts "Collection created successfully!"
  rescue => e
    raise "Failed to create/verify collection: #{e.message}"
  end
end
