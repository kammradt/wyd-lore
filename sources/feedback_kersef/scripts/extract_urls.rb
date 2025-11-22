#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'

html_file = ARGV[0] || 'data/article_list.html'
html = File.read(html_file)
doc = Nokogiri::HTML(html)

# Find all article links
article_links = doc.css('h3 a').map { |link| link['href'] }.compact
article_links = article_links.select { |url| url.include?('/articles/') }

# Output unique URLs
article_links.uniq.each do |url|
  puts url.start_with?('http') ? url : "https://feedback.kersef.com#{url}"
end

puts "\nTotal articles found: #{article_links.uniq.size}" if STDERR.tty?

