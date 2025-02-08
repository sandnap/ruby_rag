require_relative "PageScraper"
require_relative "ContentChunker"
require_relative "ChunkEmbedder"

class RagService
  def initialize(url, link_filter = nil)
    @url = url
    @link_filter = link_filter
    setup_knowledge_base(url)
  end

  def call(question)
    # Ignore this for now
    # search_similar_chunks(question)
    prompt = build_prompt(question)
    run_completion(prompt)
  end

  private

  def setup_knowledge_base(url)
    # Extract content and links from the URL
    scraper = PageScraper.new(url, @link_filter)
    result = scraper.scrape

    # Process the main content
    chunker = ContentChunker.new
    @chunks = chunker.chunk(result[:content])

    # puts "Links: #{result[:links]}"

    # Process linked pages, only going 1 level deep
    result[:links][1..2].each do |link|
      puts "Link: #{link}"
      link_scraper = PageScraper.new(link, @link_filter)
      link_result = link_scraper.scrape
      @chunks.concat(chunker.chunk(link_result[:content]))
    rescue => e
      puts "Error processing link #{link}: #{e.message}"
    end

    puts "Chunks: #{@chunks.length}"
    puts "Tokens: #{@chunks.map(&:length).sum}"
    c = File.open("chunks.txt", "w")
    0..9.times do |i|
      # The "a" flag opens the file in append mode, adding content to the end rather than overwriting
      c.puts "Chunk #{i}: #{@chunks[i]}"
    end

    # Create embeddings
    embedder = ChunkEmbedder.new
    # @text_embeddings = embedder.embed_chunks(@chunks)
    @text_embeddings = embedder.embed_chunks(@chunks[0..9])
    puts "Text embeddings: #{@text_embeddings.length}"
    e = File.open("text_embeddings.txt", "w")
    0..9.times do |i|
      # The "a" flag opens the file in append mode, adding content to the end rather than overwriting
      e.puts "Chunk #{i}: #{@text_embeddings[i]}"
    end
  end

  def create_index
    # Ignore this for now
    d = @text_embeddings.shape[1]
    @index = Faiss::IndexFlatL2.new(d)
    @index.add(@text_embeddings)
  end

  def search_similar_chunks(question, k = 2)
    # Ignore this for now
    # Ensure index exists before searching
    # raise "No index available. Please load and process text first." if @index.nil?

    # question_embedding = get_text_embedding(question)
    # distances, indices = @index.search([question_embedding], k)
    # index_array = indices.to_a[0]
    # @retrieved_chunks = index_array.map { |i| @chunks[i] }
  end

  def build_prompt(question)
    # Ignore this for now
    <<-PROMPT
    Context information is below.
    ---------------------
    #{@retrieved_chunks.join("\n---------------------\n")}
    ---------------------
    Given the context information and not prior knowledge, answer the query.
    Query: #{question}
    Answer:
    PROMPT
  end

  def run_completion(user_message, model: "gpt-3.5-turbo")
    # Ignore this for now
    response = @client.chat(
      parameters: {
        model: model,
        messages: [{role: "user", content: user_message}],
        temperature: 0.0
      }
    )
    response.dig("choices", 0, "message", "content")
  end
end

# This line checks if the current file is being run directly (not imported as a module)
# $PROGRAM_NAME (or $0) contains the name of the script being executed
# __FILE__ contains the name of the current file
# So this conditional only runs the code below when this file is run directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.length > 2
    puts "Usage: bundle exec ruby RagService.rb <sitemap_url> [link_filter]"
    puts "Example: bundle exec ruby RagService.rb https://flowbite.com/docs/sitemap.xml 'getting-started'"
    puts "Example with regex: bundle exec ruby RagService.rb https://flowbite.com/docs/sitemap.xml '^/docs/getting-started'"
    exit 1
  end

  url = ARGV[0]
  link_filter = ARGV[1] if ARGV[1]
  rag_service = RagService.new(url, link_filter)
  # Uncomment to use:
  # answer = rag_service.call("Your question here")
  # puts answer
end
