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

    # Verify first embedding
    if embeddings.first
      puts "\nFirst embedding verification:"
      puts "Dimensions: #{embeddings.first.length}"
      puts "Sample values: #{embeddings.first.take(5).inspect}"
    end

    points = chunks.zip(embeddings).map.with_index do |(chunk, embedding), id|
      # Ensure all vector values are proper floats
      vector = embedding.map { |v| v.to_f }

      {
        id: id,
        vector: vector,
        payload: {
          content: chunk,
          url: url
        }
      }
    end

    # Verify first point's vector
    if points.first
      puts "\nFirst point verification:"
      puts "Vector dimensions: #{points.first[:vector].length}"
      puts "Sample vector values: #{points.first[:vector].take(5).inspect}"
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
