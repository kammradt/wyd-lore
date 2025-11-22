#!/usr/bin/env ruby
# frozen_string_literal: true

require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'fileutils'
require 'uri'
require 'open-uri'
require 'digest'

# Capybara configuration
Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :selenium_headless
Capybara.default_max_wait_time = 10

# Main Scraper class
class WydScraper
  include Capybara::DSL

  # CONFIGURE THIS: Set your target URL here
  BASE_URL = 'https://feedback.kersef.com/pt-br/knowledge-bases/21-faq-wyd-global/categories/19-guias-do-jogo-pt-br/articles'
  
  # CSS selector for article links on the WYD FAQ page
  ARTICLE_SELECTOR = 'h3 a, .article-link'
  
  def initialize(base_url: BASE_URL, output_dir: 'data')
    @base_url = base_url
    @output_dir = output_dir
    @visited_urls = Set.new
    
    setup_directories
  end

  def scrape
    puts "Starting scraper for: #{@base_url}"
    
    begin
      visit @base_url
      puts "✓ Opened base URL: #{@base_url}"
      
      # Wait for page to load
      page.has_css?('body')
      
      # Find all topic links
      topic_links = extract_topic_links
      puts "Found #{topic_links.size} topics to scrape"
      
      # Scrape each topic
      topic_links.each_with_index do |link, index|
        scrape_topic(link, index + 1, topic_links.size)
      end
      
      puts "\n✓ Scraping complete! Data saved to: #{@output_dir}"
      
    rescue StandardError => e
      puts "✗ Error during scraping: #{e.message}"
      puts e.backtrace.join("\n")
    ensure
      Capybara.current_session.driver.quit
    end
  end

  private

  def setup_directories
    FileUtils.mkdir_p(@output_dir)
    FileUtils.mkdir_p(File.join(@output_dir, 'topics'))
    FileUtils.mkdir_p(File.join(@output_dir, 'assets', 'images'))
    puts "✓ Created output directories"
  end

  def extract_topic_links
    links = []
    
    # Find all article heading links (h3 > a structure on WYD FAQ site)
    all('h3 a, .article-link').each do |link|
      href = link[:href]
      next unless href
      
      absolute_url = make_absolute_url(href)
      
      # Filter for article URLs
      if absolute_url.include?('/articles/') && !@visited_urls.include?(absolute_url)
        links << absolute_url
      end
    end
    
    links.uniq
  end

  def scrape_topic(url, current, total)
    return if @visited_urls.include?(url)
    
    @visited_urls.add(url)
    puts "\n[#{current}/#{total}] Scraping: #{url}"
    
    begin
      visit url
      
      # Wait for content to load
      page.has_css?('body')
      
      # Generate filename from URL
      filename = generate_filename(url)
      html_path = File.join(@output_dir, 'topics', "#{filename}.html")
      
      # Save HTML
      html_content = page.html
      File.write(html_path, html_content)
      puts "  ✓ Saved HTML: #{filename}.html"
      
      # Extract and download images
      download_images(html_content, filename)
      
    rescue StandardError => e
      puts "  ✗ Error scraping #{url}: #{e.message}"
    end
  end

  def download_images(html_content, topic_name)
    # Extract image URLs from HTML
    image_urls = html_content.scan(/src=["']([^"']+\.(?:jpg|jpeg|png|gif|webp|svg))[^"']*["']/i).flatten
    
    return if image_urls.empty?
    
    puts "  Found #{image_urls.size} images"
    
    image_urls.uniq.each_with_index do |img_url, index|
      begin
        absolute_img_url = make_absolute_url(img_url)
        download_asset(absolute_img_url, topic_name, index)
      rescue StandardError => e
        puts "    ✗ Failed to download image #{img_url}: #{e.message}"
      end
    end
  end

  def download_asset(url, topic_name, index)
    # Generate unique filename
    extension = File.extname(URI.parse(url).path)
    extension = '.jpg' if extension.empty?
    
    filename = "#{topic_name}_img_#{index}#{extension}"
    filepath = File.join(@output_dir, 'assets', 'images', filename)
    
    # Download the image
    URI.open(url, 'rb') do |remote_file|
      File.open(filepath, 'wb') do |local_file|
        local_file.write(remote_file.read)
      end
    end
    
    puts "    ✓ Downloaded: #{filename}"
    
  rescue StandardError => e
    puts "    ✗ Error downloading #{url}: #{e.message}"
  end

  def make_absolute_url(url)
    return url if url.start_with?('http://', 'https://')
    
    uri = URI.parse(@base_url)
    base = "#{uri.scheme}://#{uri.host}"
    base += ":#{uri.port}" if uri.port && ![80, 443].include?(uri.port)
    
    if url.start_with?('/')
      "#{base}#{url}"
    else
      "#{@base_url}/#{url}"
    end
  end

  def valid_topic_url?(url)
    # Customize this method based on your site structure
    # This is a basic example that filters out common non-topic URLs
    
    return false if url.nil? || url.empty?
    return false if url.include?('#') # Skip anchors
    return false if url.end_with?('.css', '.js', '.pdf', '.zip')
    return false if url.include?('logout') || url.include?('login')
    
    # Only accept URLs from the same domain
    begin
      base_uri = URI.parse(@base_url)
      url_uri = URI.parse(url)
      base_uri.host == url_uri.host
    rescue URI::InvalidURIError
      false
    end
  end

  def generate_filename(url)
    # Create a readable filename from URL
    uri = URI.parse(url)
    path = uri.path.gsub('/', '_')
    query = uri.query ? "_#{Digest::MD5.hexdigest(uri.query)[0..8]}" : ''
    
    filename = "#{path}#{query}".gsub(/[^a-zA-Z0-9_-]/, '_')
    filename = filename[0..100] # Limit length
    filename = "page_#{Digest::MD5.hexdigest(url)[0..8]}" if filename.empty?
    
    filename
  end
end

# Run the scraper
if __FILE__ == $PROGRAM_NAME
  # Get URL from command line argument or use default
  base_url = ARGV[0] || WydScraper::BASE_URL
  output_dir = ARGV[1] || 'data'
  
  puts "="*60
  puts "WYD Web Scraper"
  puts "="*60
  puts "Target URL: #{base_url}"
  puts "Output Directory: #{output_dir}"
  puts "="*60
  puts
  
  scraper = WydScraper.new(base_url: base_url, output_dir: output_dir)
  scraper.scrape
end

