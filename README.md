# WYD (With Your Destiny) Project

A comprehensive documentation and scraping project for the MMORPG "With Your Destiny" (WYD).

## 📚 Project Structure

```
wyd/
├── README.md
├── Gemfile                          # Ruby dependencies (shared)
└── sources/
    └── feedback_kersef/             # WYD FAQ scraping project
        ├── scraper.rb               # Main Capybara-based web scraper
        ├── extract_urls.rb          # Helper: extract article URLs
        ├── download_articles.rb     # Helper: download articles
        ├── html_to_markdown.rb      # HTML to Markdown converter
        └── data/                    # Downloaded content
            ├── articles/
            │   ├── *.html           # 78 original HTML articles
            │   └── markdown/        # 78 Markdown files with local images
            │       └── *.md
            └── images/              # 423 images (linked in markdown)
```

## 🎯 What Was Scraped & Processed

Successfully downloaded from **WYD Global FAQ** (feedback.kersef.com):

- **78 complete HTML articles** (original format)
- **78 Markdown files** (converted with local images linked)
- **393 images properly linked** in markdown files

Content covers:
  - Game lore and history
  - Character guides and skills
  - Quest walkthroughs
  - Maps (Armia, Nippleheim, Submundo, Kefra Dungeon)
  - System guides (Refinement, Kingdoms, Painting, Guilds)
  - Celestial/Sub-Celestial mechanics
  - Mount system, Arena, Evasion
  - NPCs and items

- **423 images** including:
  - Maps and screenshots
  - Item icons and sprites
  - UI elements
  - Quest diagrams

## 🛠️ Ruby Scraper Usage

### Installation

```bash
# Install dependencies from root
bundle install
```

### Running the Scraper

The `scraper.rb` file is a Capybara-based scraper that can be used for future scraping needs:

```bash
cd sources/feedback_kersef

# Using default configuration (WYD FAQ site)
ruby scraper.rb

# Custom URL
ruby scraper.rb "https://example.com/forum"

# Custom URL and output directory
ruby scraper.rb "https://example.com/forum" "custom_output"
```

### Features

- ✅ Headless Chrome automation via Selenium
- ✅ Automatic HTML download for each page
- ✅ Image extraction and download (jpg, png, gif, webp, svg)
- ✅ Duplicate URL prevention
- ✅ Organized file structure
- ✅ Error handling and retry logic
- ✅ No hard sleeps (uses Capybara's smart waiting)

### Configuration

Edit `sources/feedback_kersef/scraper.rb` to customize:

```ruby
# Line 27: Set your target URL
BASE_URL = 'https://feedback.kersef.com/...'

# Line 30: Adjust CSS selectors for your site
ARTICLE_SELECTOR = 'h3 a, .article-link'
```

## 📝 HTML to Markdown Conversion

Convert HTML articles to Markdown format with local images:

```bash
cd sources/feedback_kersef

# Convert all HTML files to Markdown
ruby html_to_markdown.rb
```

This will:
- Convert all HTML files in `data/articles/` to Markdown
- Save them to `data/articles/markdown/`
- Automatically link local images using relative paths (`../../images/`)
- Preserve original filenames with `.md` extension

The markdown files can be opened locally and will display all images correctly!

## 📖 Content Overview

### Major Topics Covered

- **Lore**: História (History of WYD universe, gods, celestial battles)
- **Characters**: Classes, skills (9th, 10th, 11th, 12th skills)
- **Progression**: Level unlocks (40, 90, 200, 240-360), Celestial creation
- **Combat**: Macros, Critical attacks, Evasion system
- **Equipment**: Ancient weapons, Refinement (+0 to +15), Arch weapons
- **Social**: Guilds, Groups, Kingdom Wars, Replation
- **Dungeons**: Kefra, Coliseum, Arena Real, Zona Infernal
- **Quests**: Arch Contract, Celestial Traces, Valkyrie Queen
- **Systems**: Mounts, Painting, Runes, Premium Neil, NPCs

## 🔧 Technical Details

### Dependencies

- `capybara` ~> 3.40
- `selenium-webdriver` ~> 4.16
- `nokogiri` ~> 1.16

### Browser Requirements

- Chrome/Chromium browser installed
- ChromeDriver (installed automatically by selenium-webdriver)

### Notes

- Some images from `web.archive.org` failed to download (connection refused) but all primary content was successfully retrieved
- JavaScript is not necessary for this site (static HTML content)
- Rate limiting: 0.5s delay between requests to be respectful to the server

## 📝 License

This is a documentation and archival project for the WYD community. All game content belongs to its respective copyright holders.

## 🎮 About WYD

"With Your Destiny" is an MMORPG featuring:
- Fantasy lore with gods (Yetzirah, Tzfah, Armia, Kafma, etc.)
- Multiple continents (Armia, Nippleheim, Akeronia, Hekalotia)
- Character progression to Celestial and Arch forms
- Kingdom-based PvP warfare
- Complex crafting and refinement systems

---

**Last Updated**: November 22, 2025  
**Articles Scraped**: 78  
**Images Downloaded**: 423  
**Source**: https://feedback.kersef.com/pt-br/knowledge-bases/21-faq-wyd-global/

