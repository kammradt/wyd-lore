#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require 'open-uri'
require 'uri'

# Read URLs from file
urls_file = ARGV[0] || 'data/article_urls.txt'
urls = File.readlines(urls_file).map(&:strip).reject(&:empty?)

puts "Found #{urls.size} articles to download"
puts "="*60

urls.each_with_index do |url, index|
  begin
    # Extract article ID and slug from URL
    match = url.match(%r{/articles/(\d+-[\w-]+)})
    next unless match
    
    article_slug = match[1]
    puts "\n[#{index + 1}/#{urls.size}] Downloading: #{article_slug}"
    
    # Download HTML
    html_path = "data/articles/#{article_slug}.html"
    puts "  → Fetching HTML..."
    html_content = URI.open(url).read
    File.write(html_path, html_content)
    puts "  ✓ Saved HTML (#{(File.size(html_path) / 1024.0).round(1)} KB)"
    
    # Parse HTML to find images
    doc = Nokogiri::HTML(html_content)
    images = doc.css('img').map { |img| img['src'] }.compact
    
    if images.any?
      puts "  → Found #{images.size} images"
      
      images.each_with_index do |img_url, img_idx|
        next if img_url.start_with?('data:') # Skip data URLs
        
        # Make absolute URL
        img_url = "https://feedback.kersef.com#{img_url}" unless img_url.start_with?('http')
        
        # Get file extension
        ext = File.extname(URI.parse(img_url).path)
        ext = '.jpg' if ext.empty?
        
        # Save image
        img_filename = "#{article_slug}_img_#{img_idx}#{ext}"
        img_path = "data/images/#{img_filename}"
        
        begin
          URI.open(img_url) do |remote|
            File.open(img_path, 'wb') { |file| file.write(remote.read) }
          end
          size_kb = (File.size(img_path) / 1024.0).round(1)
          puts "    ✓ #{img_filename} (#{size_kb} KB)" if size_kb > 1
        rescue StandardError => e
          puts "    ✗ Failed to download image: #{e.message}"
        end
      end
    else
      puts "  → No images found"
    end
    
    # Be nice to the server
    sleep 0.5
    
  rescue StandardError => e
    puts "  ✗ Error: #{e.message}"
  end
end

puts "\n" + "="*60
puts "✓ Download complete!"
puts "  Articles: data/articles/"
puts "  Images: data/images/"

