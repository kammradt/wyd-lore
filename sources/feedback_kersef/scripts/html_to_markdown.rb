#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# Configuration
ARTICLES_DIR = 'data/articles'
MARKDOWN_DIR = 'data/articles/markdown'
IMAGES_DIR = 'data/images'

# Create markdown directory
FileUtils.mkdir_p(MARKDOWN_DIR)

# Get all HTML files
html_files = Dir.glob("#{ARTICLES_DIR}/*.html").sort

puts "="*60
puts "HTML to Markdown Converter"
puts "="*60
puts "Found #{html_files.size} HTML files to convert"
puts

html_files.each_with_index do |html_file, index|
  basename = File.basename(html_file, '.html')
  markdown_file = File.join(MARKDOWN_DIR, "#{basename}.md")
  
  puts "[#{index + 1}/#{html_files.size}] Converting: #{basename}"
  
  # Convert HTML to Markdown using markitdown
  result = `markitdown "#{html_file}" 2>&1`
  
  if $?.success?
    # Write the markdown content
    File.write(markdown_file, result)
    puts "  ✓ Converted to Markdown"
    
    # Now replace image URLs with local relative paths
    markdown_content = File.read(markdown_file)
    
    # Find all local images for this article
    article_images = Dir.glob("#{IMAGES_DIR}/#{basename}_img_*.*")
    
    if article_images.any?
      puts "  → Linking #{article_images.size} local images"
      
      # Replace remote image URLs with local relative paths
      # The images are in ../images/ relative to the markdown file
      article_images.each do |img_path|
        img_filename = File.basename(img_path)
        
        # Try to find and replace various URL patterns for this image
        # Pattern 1: Full URLs
        markdown_content.gsub!(/!\[([^\]]*)\]\(https?:\/\/[^\)]*#{Regexp.escape(img_filename.split('_img_').last)}\)/) do |match|
          alt_text = $1
          "![#{alt_text}](../../images/#{img_filename})"
        end
        
        # Pattern 2: Look for any reference to this specific image file
        img_index = img_filename.match(/_img_(\d+)\./)[1] rescue nil
        if img_index
          # Replace patterns that might reference this image
          markdown_content.gsub!(/!\[([^\]]*)\]\((?:https?:\/\/)?[^\)]*\.(jpg|jpeg|png|gif|webp|bmp|svg)\)/) do |match|
            # Check if this is approximately the right image by position
            # For now, we'll keep the original URL but this could be improved
            match
          end
        end
      end
      
      # Additional pass: Replace any remaining absolute image URLs with relative paths if we can match them
      markdown_content.gsub!(/!\[([^\]]*)\]\((https?:\/\/[^\)]+\/([\w\-]+\.(jpg|jpeg|png|gif|webp|bmp|svg|PNG)))\)/) do |match|
        alt_text = $1
        url = $2
        filename = $3
        
        # Check if we have a local version
        local_image = article_images.find { |img| File.basename(img).include?(filename.downcase) }
        
        if local_image
          "![#{alt_text}](../../images/#{File.basename(local_image)})"
        else
          match # Keep original if no local copy
        end
      end
      
      File.write(markdown_file, markdown_content)
      puts "  ✓ Linked local images"
    else
      puts "  → No images to link"
    end
    
    size_kb = (File.size(markdown_file) / 1024.0).round(1)
    puts "  ✓ Saved (#{size_kb} KB)"
    
  else
    puts "  ✗ Error: #{result}"
  end
  
  puts
end

puts "="*60
puts "✓ Conversion complete!"
puts "  Markdown files: #{MARKDOWN_DIR}/"
puts "  Total files: #{Dir.glob("#{MARKDOWN_DIR}/*.md").size}"

