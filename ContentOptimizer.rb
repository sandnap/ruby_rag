require "httparty"

class ContentOptimizer
  OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
  MAX_CHUNK_SIZE = 150000  # Conservative limit to leave room for prompt

  def initialize
    @api_key = ENV.fetch("OPENROUTER_API_KEY")
  end

  def optimize(content)
    # If content is small enough, process it directly
    return process_chunk(content) if content.length <= MAX_CHUNK_SIZE

    # Split content into chunks at paragraph boundaries
    chunks = split_into_chunks(content)
    puts "Content split into #{chunks.length} chunks for processing"

    # Process each chunk and combine results
    results = chunks.map.with_index do |chunk, index|
      puts "\nProcessing chunk #{index + 1} of #{chunks.length} (#{chunk.length} characters)"
      process_chunk(chunk)
    end

    # Combine the results
    results.join("\n\n")
  end

  private

  def split_into_chunks(content)
    chunks = []
    paragraphs = content.split(/\n\n+/)
    current_chunk = ""

    paragraphs.each do |paragraph|
      if (current_chunk.length + paragraph.length + 2) <= MAX_CHUNK_SIZE
        current_chunk += current_chunk.empty? ? paragraph : "\n\n#{paragraph}"
      else
        chunks << current_chunk.strip unless current_chunk.empty?
        current_chunk = paragraph
      end
    end

    chunks << current_chunk.strip unless current_chunk.empty?
    chunks
  end

  def process_chunk(content)
    prompt = <<~PROMPT
      You are a content optimization assistant. Your task is to:
      1. Convert the provided HTML/text content into clean, well-formatted markdown
      2. Ensure all code examples are properly wrapped in markdown code blocks with appropriate language tags
      3. Preserve the semantic structure and meaning of the content
      4. Remove any unnecessary HTML tags or formatting
      5. Keep the content informative and clear
      6. Only output the markdown, no other text or comments
      7. Do not add "```markdown" tags to the results

      Here is the content to optimize:

      #{content}

      Please provide the optimized markdown version, ensuring all code examples are properly formatted.
    PROMPT

    body = {
      model: "openai/gpt-4o-mini", # "anthropic/claude-3.5-haiku:beta"
      messages: [
        {
          role: "user",
          content: [
            {type: "text", text: prompt},
            {type: "text", text: content}
          ]
        }
      ]
    }.to_json

    result = HTTParty.post(
      OPENROUTER_URL,
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer #{@api_key}"
      },
      body: body
    )

    case result.code
    when 200
      result.parsed_response.dig("choices", 0, "message", "content")
    else
      puts "Warning: Error optimizing content (#{result.code}): #{result.body}"
      content
    end
  rescue => e
    puts "Warning: Error optimizing content: #{e.message}"
    content
  end
end
