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

  private

  def setup_knowledge_base(url)
    # Extract content and links from the URL
    scraper = PageScraper.new(url, @link_filter, @content_start_pattern, @content_end_pattern)
    result = scraper.scrape

    # Process the main content
    chunker = ContentChunker.new
    @chunks = []
    @chunk_metadata = []  # Store metadata for each chunk

    if result[:content]
      # Optimize content before chunking
      puts "Optimizing main page content..."
      optimized_content = @optimizer.optimize(result[:content])
      page_chunks = chunker.chunk(optimized_content)

      # Add chunks with metadata
      page_chunks.each_with_index do |chunk, index|
        @chunks << chunk
        @chunk_metadata << {url: url, chunk_number: index}
      end

      puts "Found content in main page, extracted #{page_chunks.length} chunks"
    else
      puts "No matching content found in main page"
    end

    # Process linked pages, only going 1 level deep
    processed_count = 0
    skipped_count = 0

    result[:links][1..2].each do |link|
      puts "\nProcessing: #{link}"
      link_scraper = PageScraper.new(link, @link_filter, @content_start_pattern, @content_end_pattern)
      link_result = link_scraper.scrape

      if link_result[:content]
        puts "Optimizing linked page content..."
        optimized_content = @optimizer.optimize(link_result[:content])
        page_chunks = chunker.chunk(optimized_content)

        # Add chunks with metadata
        page_chunks.each_with_index do |chunk, index|
          @chunks << chunk
          @chunk_metadata << {url: link, chunk_number: index}
        end

        processed_count += 1
        puts "Found content, extracted #{page_chunks.length} chunks"
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
    @store.store_embeddings(@chunks, @text_embeddings, @chunk_metadata)
    puts "Embeddings stored successfully!"
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

  RagService.new(url, collection_name, link_filter, content_start_pattern, content_end_pattern)
end
