# This class should be responsible for chunking the text into smaller chunks (2048).

class ContentChunker
  def initialize(chunk_size = 2048)
    @chunk_size = chunk_size
  end

  def chunk(text)
    # Clean up the text first - remove multiple empty lines and normalize spacing
    cleaned_text = text.gsub(/\n{3,}/, "\n\n")  # Replace 3+ newlines with 2
      .gsub(/[^\S\n]+/, " ")     # Replace multiple spaces with single space
      .strip                      # Remove leading/trailing whitespace

    # Split by paragraphs
    paragraphs = cleaned_text.split(/\n\n+/)
      .map(&:strip)
      .reject(&:empty?)

    chunks = []
    current_chunk = ""

    paragraphs.each do |paragraph|
      # If the paragraph itself is too long, split it into smaller pieces
      if paragraph.length > @chunk_size
        # Add the current chunk if it's not empty
        chunks << current_chunk.strip unless current_chunk.empty?
        current_chunk = ""

        # Split the long paragraph into smaller pieces
        words = paragraph.split(/\s+/)
        temp_chunk = ""

        words.each do |word|
          if (temp_chunk.length + word.length + 1) <= @chunk_size
            temp_chunk += temp_chunk.empty? ? word : " #{word}"
          else
            chunks << temp_chunk.strip unless temp_chunk.empty?
            temp_chunk = word
          end
        end

        chunks << temp_chunk.strip unless temp_chunk.empty?
      elsif (current_chunk.length + paragraph.length + 2) <= @chunk_size
        # Handle normal paragraphs
        current_chunk += current_chunk.empty? ? paragraph : "\n\n#{paragraph}"
      else
        chunks << current_chunk.strip unless current_chunk.empty?
        current_chunk = paragraph
      end
    end

    chunks << current_chunk.strip unless current_chunk.empty?

    # Verify all chunks are within size limit
    chunks.each_with_index do |chunk, i|
      if chunk.length > @chunk_size
        puts "Warning: Chunk #{i} exceeds size limit (#{chunk.length} > #{@chunk_size})"
      end
    end

    chunks
  end
end
