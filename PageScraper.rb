# This class will be responsible for scraping the page at the provided URL returning the title and body of the page.
# The code here should be modified accordingly.
require "nokogiri"
require "net/http"
require "voyageai"

class PageScraper
  def initialize(url, link_filter = nil, content_start_pattern = nil, content_end_pattern = nil)
    @url = url
    @link_filter = link_filter
    @content_start_pattern = content_start_pattern
    @content_end_pattern = content_end_pattern
  end

  def scrape
    doc = fetch_page(@url)
    {
      content: extract_content(doc),
      links: extract_links(doc)
    }
  end

  private

  def fetch_page(url)
    Nokogiri::HTML(Net::HTTP.get(URI.parse(url)))
  end

  def extract_content(doc)
    title = doc.at_css("title")&.inner_html || ""

    if @content_start_pattern && @content_end_pattern
      # Get the raw HTML as a string
      content = doc.to_html

      # Create a regex that matches everything between start and end patterns
      pattern = /#{@content_start_pattern}(.*?)#{@content_end_pattern}/m

      if (match = content.match(pattern))
        main_content = match[1].strip
      else
        puts "Warning: Content patterns not found in page with title: #{title}"
        return nil
      end
    else
      main_content = doc.at_xpath("//main")&.inner_html || doc.at_css("body").inner_html
    end

    "Title: #{title}\n\nContent: #{main_content}"
  end

  def extract_links(doc)
    links = if @url.end_with?("sitemap.xml")
      doc.css("loc").map(&:text).uniq
    else
      doc.css("a").map { |link| link["href"] }.compact
        .select { |href| href.start_with?("http", "/") }
        .map { |href| href.start_with?("/") ? URI.join(@url, href).to_s : href }
        .uniq
    end

    return links unless @link_filter

    pattern = @link_filter.is_a?(Regexp) ? @link_filter : Regexp.new(@link_filter.to_s)
    links.select { |link| link.match?(pattern) }
  end
end
