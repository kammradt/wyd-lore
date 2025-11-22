#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'fileutils'

# URLs and paths
PAGE_URL = 'https://wydglobal.raidhut.com/pt-br/2402'
OUTPUT_DIR = 'data'
ARTICLES_DIR = "#{OUTPUT_DIR}/articles"
IMAGES_DIR = "#{OUTPUT_DIR}/images"

puts "="*60
puts "Raid Hut Quest Page Scraper"
puts "="*60
puts "Downloading: #{PAGE_URL}"

# Create directories
FileUtils.mkdir_p(ARTICLES_DIR)
FileUtils.mkdir_p(IMAGES_DIR)

# Download the HTML page with proper headers
html_content = URI.open(PAGE_URL, 
  'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
).read

# Save the original HTML
html_path = "#{ARTICLES_DIR}/quests_mortais.html"
File.write(html_path, html_content)
puts "✓ Saved HTML: #{(File.size(html_path) / 1024.0).round(1)} KB"

# Parse HTML to find images
doc = Nokogiri::HTML(html_content)
images = doc.css('img').map { |img| img['src'] }.compact.uniq

puts "\nFound #{images.size} images"

# Download images
images.each_with_index do |img_url, idx|
  begin
    # Skip data URLs and external domains we don't want
    next if img_url.start_with?('data:')
    
    # Make absolute URL
    img_url = "https://wydglobal.raidhut.com#{img_url}" unless img_url.start_with?('http')
    
    # Get filename from URL or create one
    filename = File.basename(URI.parse(img_url).path)
    filename = "quest_image_#{idx}#{File.extname(filename)}" if filename.empty?
    
    img_path = "#{IMAGES_DIR}/#{filename}"
    
    # Download image
    URI.open(img_url, 'rb') do |remote|
      File.open(img_path, 'wb') { |file| file.write(remote.read) }
    end
    
    size_kb = (File.size(img_path) / 1024.0).round(1)
    puts "  ✓ #{filename} (#{size_kb} KB)" if size_kb > 0.1
    
  rescue StandardError => e
    puts "  ✗ Failed: #{img_url} - #{e.message}"
  end
end

puts "\n" + "="*60
puts "✓ Download complete!"
puts "  HTML: #{html_path}"
puts "  Images: #{IMAGES_DIR}/"

