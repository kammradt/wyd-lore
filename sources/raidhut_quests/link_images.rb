#!/usr/bin/env ruby
# frozen_string_literal: true

MARKDOWN_FILE = 'data/articles/markdown/quests_mortais.md'
IMAGES_DIR = 'data/images'

puts "="*60
puts "Linking Local Images in Markdown"
puts "="*60

# Read markdown content
content = File.read(MARKDOWN_FILE)

# Get all local images
local_images = Dir.glob("#{IMAGES_DIR}/*").map { |path| File.basename(path) }

puts "Found #{local_images.size} local images"

# Replace image URLs with local paths
original_content = content.dup
linked_count = 0

# Replace image markdown syntax
content.gsub!(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
  alt_text = $1
  url = $2
  
  # Skip data URLs
  next match if url.start_with?('data:')
  
  # Extract filename from URL (handle various formats)
  # e.g., /./images/file.jpg or /images/2024/Maio/02/file.png
  filename = File.basename(url.split('/').last) rescue nil
  
  # Check if we have this image locally
  if filename && local_images.include?(filename)
    linked_count += 1
    "![#{alt_text}](../../images/#{filename})"
  else
    match # Keep original if no local copy
  end
end

# Save updated markdown
if content != original_content
  File.write(MARKDOWN_FILE, content)
  puts "✓ Linked #{linked_count} images"
  puts "✓ Updated markdown file"
else
  puts "→ No image links to update"
end

puts "="*60
puts "✓ Complete!"

