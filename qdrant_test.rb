require "qdrant"

class QdrantTest
  def initialize
    @client = Qdrant::Client.new(
      url: "http://localhost:6333",
      api_key: nil # Add API key if using authentication
    )
  end

  def test_connection
    # Try to get collection list as a basic connectivity test
    collections = @client.collections.list
    puts "Successfully connected to Qdrant!"
    puts "Available collections: #{collections.collections.map(&:name).join(", ")}"
    true
  rescue => e
    puts "Failed to connect to Qdrant: #{e.message}"
    false
  end

  def create_test_collection
    # Create a test collection with 384 dimensions (matching voyage-code-3)
    @client.collections.create(
      collection_name: "test_collection",
      vectors: {
        size: 384,
        distance: "Cosine"
      }
    )
    puts "Test collection created successfully!"
    true
  rescue => e
    puts "Failed to create collection: #{e.message}"
    false
  end
end

# Example usage:
if __FILE__ == $PROGRAM_NAME
  qdrant = QdrantTest.new
  qdrant.test_connection
  qdrant.create_test_collection
end
