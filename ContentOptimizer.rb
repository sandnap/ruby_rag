require "httparty"

class ContentOptimizer
  OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

  def initialize
    @api_key = ENV.fetch("OPENROUTER_API_KEY")
  end

  def optimize(content)
    prompt = <<~PROMPT
      You are a content optimization assistant. Your task is to:
      1. Convert the provided HTML/text content into clean, well-formatted markdown
      2. Ensure all code examples are properly wrapped in markdown code blocks with appropriate language tags
      3. Preserve the semantic structure and meaning of the content
      4. Remove any unnecessary HTML tags or formatting
      5. Keep the content informative and clear

      Here is the content to optimize:

      #{content}

      Please provide the optimized markdown version, ensuring all code examples are properly formatted.
    PROMPT

    body = {
      model: "anthropic/claude-3.5-haiku:beta",
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
      puts "Result: #{result}"
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
