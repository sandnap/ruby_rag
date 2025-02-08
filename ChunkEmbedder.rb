require "voyageai"

class ChunkEmbedder
  def initialize
    @client = VoyageAI::Client.new(
      api_key: ENV.fetch("VOYAGE_API_KEY")
    )
  end

  def embed_chunks(chunks)
    embed = @client.embed(
      chunks,
      model: "voyage-code-3"
    )
    embed.embeddings
    # chunks.map do |chunk|
    #   response = @client.embed(
    #     input: chunk,
    #     model: "voyage-code-3"
    #   )
    #   response.embedding
    # end
  end
end
