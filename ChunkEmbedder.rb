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

      # Verify embeddings are non-zero
      batch_embeddings = embed.embeddings
      if batch_embeddings.first
        puts "Sample values from first embedding in batch:"
        puts batch_embeddings.first.take(5).inspect
      end

      embeddings.concat(batch_embeddings)
    end

    puts "Created #{embeddings.length} embeddings"
    puts "First embedding dimensions: #{embeddings.first.length}"
    puts "Sample values from final first embedding:"
    puts embeddings.first.take(5).inspect

    embeddings
  end
end
