require "voyageai"

class ChunkEmbedder
  BATCH_SIZE = 128

  def initialize
    @client = VoyageAI::Client.new(
      api_key: ENV.fetch("VOYAGE_API_KEY")
    )
  end

  def embed_chunks(chunks)
    puts "Creating embeddings in batches of #{BATCH_SIZE}..."
    embeddings = []
    total_batches = (chunks.length.to_f / BATCH_SIZE).ceil

    chunks.each_slice(BATCH_SIZE).with_index do |batch, index|
      puts "Processing batch #{index + 1} of #{total_batches} (#{batch.length} chunks)..."
      embed = @client.embed(
        batch,
        model: "voyage-code-3"
      )
      embeddings.concat(embed.embeddings)
    end

    puts "Created #{embeddings.length} embeddings"
    embeddings
  end
end
