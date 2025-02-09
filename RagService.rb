require_relative "PageScraper"
require_relative "ContentChunker"
require_relative "ChunkEmbedder"
require_relative "ContentOptimizer"
require_relative "QdrantStore"

class RagService
  def initialize(url, collection_name, link_filter = nil, content_start_pattern = nil, content_end_pattern = nil)
    @url = url
    @collection_name = collection_name
    @link_filter = link_filter
    @content_start_pattern = content_start_pattern
    @content_end_pattern = content_end_pattern
    @optimizer = ContentOptimizer.new
    @store = QdrantStore.new(collection_name)
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
    scraper = PageScraper.new(url, @link_filter, @content_start_pattern, @content_end_pattern)
    result = scraper.scrape

    # Process the main content
    chunker = ContentChunker.new
    @chunks = []

    if result[:content]
      # Optimize content before chunking
      puts "Optimizing main page content..."
      optimized_content = @optimizer.optimize(result[:content])
      @chunks = chunker.chunk(optimized_content)
      puts "Found content in main page, extracted #{@chunks.length} chunks"
    else
      puts "No matching content found in main page"
    end

    # Process linked pages, only going 1 level deep
    processed_count = 0
    skipped_count = 0

    result[:links][1..5].each do |link|
      puts "\nProcessing: #{link}"
      link_scraper = PageScraper.new(link, @link_filter, @content_start_pattern, @content_end_pattern)
      link_result = link_scraper.scrape

      if link_result[:content]
        puts "Optimizing linked page content..."
        optimized_content = @optimizer.optimize(link_result[:content])
        new_chunks = chunker.chunk(optimized_content)
        @chunks.concat(new_chunks)
        processed_count += 1
        puts "Found content, extracted #{new_chunks.length} chunks"
      else
        skipped_count += 1
        puts "No matching content found"
      end
    rescue => e
      skipped_count += 1
      puts "Error processing #{link}: #{e.message}"
    end

    puts "\nProcessing Summary:"
    puts "Total pages processed successfully: #{processed_count + (@chunks.empty? ? 0 : 1)}"
    puts "Pages skipped/errored: #{skipped_count}"
    puts "Total chunks extracted: #{@chunks.length}"
    puts "Total characters: #{@chunks.map(&:length).sum}"

    return if @chunks.empty?

    # Create embeddings
    embedder = ChunkEmbedder.new
    @text_embeddings = embedder.embed_chunks(@chunks)
    puts "Text embeddings created: #{@text_embeddings.length}"

    # Store in Qdrant
    puts "Storing embeddings in Qdrant collection '#{@collection_name}'..."
    @store.store_embeddings(@chunks, @text_embeddings, @url)
    puts "Embeddings stored successfully!"
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
  if ARGV.empty? || ARGV.length > 5
    puts "Usage: bundle exec ruby RagService.rb <url> <collection_name> [link_filter] [content_start_pattern] [content_end_pattern]"
    puts "Example: bundle exec ruby RagService.rb https://example.com my_collection 'docs' '<main>' '</main>'"
    puts "Example with regex: bundle exec ruby RagService.rb https://example.com docs_collection '^/docs' '## Overview' '## Installation'"
    exit 1
  end

  url = ARGV[0]
  collection_name = ARGV[1]
  link_filter = ARGV[2] if ARGV[2]
  content_start_pattern = ARGV[3] if ARGV[3]
  content_end_pattern = ARGV[4] if ARGV[4]

  rag_service = RagService.new(url, collection_name, link_filter, content_start_pattern, content_end_pattern)
  # Uncomment to use:
  # answer = rag_service.call("Your question here")
  # puts answer
end
