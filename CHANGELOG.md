# Changelog

All notable changes to the WYD Project will be documented in this file.

## [Unreleased] - 2025-11-22

### Added
- **Web Scraper Infrastructure**
  - Created Capybara-based web scraper (`scraper.rb`) for automated content extraction
  - Headless Chrome automation with Selenium WebDriver
  - Intelligent image downloading and organization
  - Duplicate URL prevention and error handling
  
- **WYD FAQ Content Collection**
  - Scraped 78 complete articles from WYD Global FAQ (feedback.kersef.com)
  - Downloaded 423 associated images (maps, screenshots, icons, UI elements)
  - Content covers: lore, quests, skills, maps, game systems, NPCs, and guides
  
- **HTML to Markdown Conversion**
  - Created `html_to_markdown.rb` using markitdown tool
  - Converted all 78 HTML articles to clean Markdown format
  - Automatic image linking with relative paths
  - 393 images successfully linked to their respective markdown files
  
- **Helper Scripts**
  - `extract_urls.rb` - Extract article URLs from HTML pages using Nokogiri
  - `download_articles.rb` - Batch download articles and images with progress tracking
  
- **Documentation**
  - Comprehensive README.md with usage instructions
  - Project structure documentation
  - Installation and configuration guides

### Project Structure
```
wyd/
├── Gemfile                          # Ruby dependencies
├── README.md                        # Project documentation
├── CHANGELOG.md                     # This file
└── sources/
    └── feedback_kersef/             # WYD FAQ scraping project
        ├── scraper.rb               # Main Capybara scraper
        ├── extract_urls.rb          # URL extraction helper
        ├── download_articles.rb     # Batch downloader
        ├── html_to_markdown.rb      # HTML to MD converter
        └── data/
            ├── articles/
            │   ├── *.html           # 78 original HTML files
            │   └── markdown/        # 78 Markdown files
            └── images/              # 423 images
```

### Content Summary
- **78 Articles** covering WYD game mechanics and lore
- **423 Images** (maps, sprites, UI elements, screenshots)
- **393 Images linked** in markdown files with relative paths
- **Average:** 5.4 images per article

### Topics Covered
- **Lore:** History of WYD universe, celestial battles, gods
- **Characters:** Classes, skills (9th-12th), progression
- **Systems:** Refinement, Kingdoms, Guilds, Mounts, Painting
- **Combat:** Macros, critical attacks, evasion, arena
- **Dungeons:** Kefra, Coliseum, Zona Infernal
- **Quests:** Arch Contract, Celestial Traces, Valkyrie Queen
- **Maps:** Armia, Nippleheim, Submundo, Dragon Field

### Technical Details
- **Language:** Ruby 3.x
- **Dependencies:** Capybara 3.40, Selenium WebDriver 4.16, Nokogiri 1.16
- **Tools:** markitdown for HTML to Markdown conversion
- **Browser:** Headless Chrome via ChromeDriver

### Notes
- Some images from web.archive.org failed to download (connection refused)
- All primary content successfully retrieved from main server
- JavaScript not required for scraping (static HTML content)
- Rate limiting: 0.5s delay between requests

