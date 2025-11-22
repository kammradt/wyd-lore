#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'fileutils'

HTML_FILE = 'data/articles/quests_mortais.html'
MARKDOWN_FILE = 'data/articles/markdown/quests_mortais.md'
IMAGES_DIR = 'data/images'

puts "="*60
puts "Fixing Quest Images"
puts "="*60

# Parse HTML to extract background-image URLs
html = File.read(HTML_FILE)
doc = Nokogiri::HTML(html)

# Find all img tags with background-image in style
background_images = []
doc.css('img[style*="background-image"]').each do |img|
  style = img['style']
  if style =~ /background-image:url\(([^)]+)\)/
    url = $1
    background_images << url
  end
end

puts "Found #{background_images.uniq.size} unique background images"

# Download the actual icon images
downloaded_files = {}
background_images.uniq.each_with_index do |url, idx|
  begin
    filename = File.basename(URI.parse(url).path)
    filepath = "#{IMAGES_DIR}/#{filename}"
    
    unless File.exist?(filepath)
      URI.open(url, 'rb') do |remote|
        File.open(filepath, 'wb') { |file| file.write(remote.read) }
      end
      puts "  ✓ Downloaded: #{filename}"
    end
    
    downloaded_files[url] = filename
    
  rescue StandardError => e
    puts "  ✗ Failed: #{url} - #{e.message}"
  end
end

# Read markdown and remove moldura.png references since they're just decorative frames
markdown = File.read(MARKDOWN_FILE)

# Count moldura references
moldura_count = markdown.scan(/!\[[^\]]*\]\([^)]*moldura\.png\)/).size

puts "\nRemoving #{moldura_count} decorative frame images (moldura.png)"

# Remove moldura.png image references (they're just decorative frames)
markdown.gsub!(/!\[[^\]]*\]\([^)]*moldura\.png\)\n*/, '')

# Save updated markdown
File.write(MARKDOWN_FILE, markdown)

puts "\n✓ Markdown updated"
puts "✓ Downloaded #{downloaded_files.size} icon images"
puts "\n" + "="*60
puts "Note: Removed decorative frame images (moldura.png)"
puts "The actual item icons are now in data/images/"

