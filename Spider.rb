require "vessel"
require "json"

# Ignore this for now
class Spider < Vessel::Cargo
  domain "flowbite.com"
  start_urls "https://flowbite.com/docs/sitemap.xml"

  def parse 
    xpath("//loc").each do |url|
      puts url.text
      # request(url.text, handle: :parse_page)
    end
  end

  def parse_page(response)
    yield response.body
  end
end

Spider.run(driver_options: {ws_url: "ws://localhost:9222"}) do |body|
  puts JSON.pretty_generate(body)
end
