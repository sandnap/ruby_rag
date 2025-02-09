#!/usr/bin/env ruby
require_relative "QdrantSearcher"

if ARGV.length < 2
  puts "Usage: bundle exec ruby search.rb <collection_name> <query>"
  puts "Example: bundle exec ruby search.rb flowbite_components 'How do I create an accordion?'"
  exit 1
end

collection_name = ARGV[0]
query = ARGV[1]

searcher = QdrantSearcher.new(collection_name)
searcher.search(query)
