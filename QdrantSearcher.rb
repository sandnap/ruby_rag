require "voyageai"
require "qdrant"

class QdrantSearcher
  def initialize(collection_name, limit = 5)
    @collection_name = collection_name
    @limit = limit
    @embedder = VoyageAI::Client.new(
      api_key: ENV.fetch("VOYAGE_API_KEY")
    )
    @qdrant = Qdrant::Client.new(
      url: "http://localhost:6333",
      api_key: nil
    )
  end

  def search(query)
    # Create embedding for the query
    puts "Creating embedding for query..."
    query_embedding = create_embedding(query)

    # Search Qdrant
    puts "Searching for similar content..."
    response = @qdrant.points.search(
      collection_name: @collection_name,
      vector: query_embedding,
      limit: @limit,
      with_payload: true,
      with_vector: false
    )

    # Process and return results
    results = response.dig("result")&.map do |match|
      {
        content: match.dig("payload", "content"),
        url: match.dig("payload", "url"),
        score: match["score"]
      }
    end

    if results&.any?
      puts "Found #{results.length} matches"
      results.each_with_index do |r, i|
        puts "\nMatch #{i + 1} (score: #{r[:score]}):"
        puts "URL: #{r[:url]}"
        puts "Content preview: #{r[:content][0..200]}..."
      end
    else
      puts "No matches found"
    end

    results
  end

  private

  def create_embedding(text)
    embed = @embedder.embed(
      text,
      model: "voyage-code-3"
    )
    embed.embeddings.first
  end
end
