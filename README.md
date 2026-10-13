# WYD (With Your Destiny) Documentation Project

> A comprehensive documentation and scraping project for the MMORPG "With Your Destiny" (WYD)

[![License](https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![Ruby](https://img.shields.io/badge/ruby-3.x-red.svg)](https://www.ruby-lang.org/)

## 📖 About

This project aims to preserve and organize the history, lore, and game mechanics of **With Your Destiny (WYD)**, a fantasy MMORPG developed by JoyImpact Co., Ltd. Through automated web scraping and careful curation, we've compiled guides, quest information, and historical records from various sources.

## ✨🌐 Future Vision

### Preserving History for Tomorrow

The primary goal of this project is to **document and preserve as much WYD history as possible**, ensuring that this 20+ year legacy remains accessible for future generations of players, researchers, and enthusiasts.

We've deliberately chosen **Markdown as our documentation format** for a powerful reason: **LLM compatibility**. By structuring all game knowledge in clean, semantic Markdown:

- 🤖 **AI-Ready**: The entire knowledge base can be fed to Large Language Models
- 🔮 **Future Applications**: Build intelligent quest assistants, lore chatbots, game wikis, and interactive guides
- 🧠 **Semantic Understanding**: LLMs can parse, analyze, and generate insights from the structured data
- 🔧 **Flexible**: Easy to transform into websites, PDFs, ebooks, or any future format
- 🌍 **Universal**: Markdown is human-readable AND machine-readable

## 📋 TODO

- [ ] Verify if all images are correctly linked in markdown files


## 🎮 About With Your Destiny (WYD)

**With Your Destiny** is a Free-to-play Fantasy MMORPG set in the world of **Kersef**, featuring:

- **Lore**: Epic story of gods (Yetzirah, Tzfah) and their conflict affecting humanity
- **Kingdoms**: Hekalotia (Blue) vs Akeronia (Red) in eternal rivalry
- **Progression**: From Mortal → Arch → Celestial → Sub-Celestial
- **Classes**: 4 unique classes with 150+ customizable skills
- **PvP**: Massive battles supporting up to 1000 simultaneous players
- **Content**: Dungeons, quests, guild wars, kingdom battles, mounts, and more

**Publisher History:**
- Original: HanbitSoft Inc. (2003)
- Current: Raid Hut Ltd. (2019-present, Global) & JoyImpact (Korea)


## 📚 Knowledge Base

The curated knowledge base lives in [`wiki/`](wiki/README.md): **84 pages** organized by topic (lore, classes, progression, quests, maps, items, systems, PvP, NPCs, events). Start at [`wiki/README.md`](wiki/README.md).

- **For humans**: each category folder has a README index with Portuguese and English titles and a one-line summary.
- **For AI agents**: [`llms.txt`](llms.txt) lists every page with an English summary, and [`llms-full.txt`](llms-full.txt) has the whole knowledge base in one file.
- **Every page has a YAML header** with `title_en`, `summary_en`, `tags`, its `sources` (original URL plus the archived copy) and a `canon` label:
  - `official`: published by the developer or publisher (JoyImpact, Raid Hut)
  - `community`: third-party writing such as Wikipedia, fan blogs and forums
  - `private-server`: content created by private servers, kept in [`wiki/servers/`](wiki/servers/README.md) and out of canon

Pages are generated from the archived sources by [`scripts/kb/build_wiki.rb`](scripts/kb/build_wiki.rb). [`manifest.yml`](scripts/kb/manifest.yml) decides which source articles feed which page (several sources can merge into one), and [`metadata.yml`](scripts/kb/metadata.yml) holds the English titles, summaries and tags.

```bash
ruby scripts/kb/build_wiki.rb                        # rebuild every page and index
ruby scripts/kb/build_wiki.rb quests/training-camp   # rebuild one page
```

The build overwrites the pages it rebuilds, so once a page is edited by hand, leave it out of later rebuilds.

## 🗄️ Archived Sources

Raw scraped copies of every source, kept unchanged under [`sources/`](sources/). The knowledge base is built from these.

### 🎮 [Feedback Kersef - Game Guides](sources/feedback_kersef/data/articles/markdown/)

<details>
<summary>78 comprehensive game guides covering:</summary>

- **Lore & History**: The creation myth, gods (Yetzirah, Tzfah, Armia, Kafma), celestial battles
- **Character Systems**: Classes (Transknight, Hunter, Foema, Beastmaster), skills (9th-12th)
- **Progression**: Level unlocks (40, 90, 200, 240-360), Celestial/Sub-Celestial creation
- **Combat & PvP**: Macros, critical attacks, evasion, Arena, Kingdom Wars
- **Equipment**: Ancient weapons, refinement systems (+0 to +15), Arch weapons
- **Dungeons & Raids**: Kefra, Coliseum, Zona Infernal, Dragon Field
- **Game Systems**: Mounts, guilds, kingdoms, painting system, NPCs
- **Quests**: Arch Contract, Celestial Traces, Valkyrie Queen, and more

📁 **423 images** including maps, item icons, UI screenshots, and quest diagrams

</details>

### 🗺️ [Raid Hut - Quest Guides](sources/raidhut_quests/data/articles/markdown/)

<details>
<summary>Complete quest progression guide (Level 1-400):</summary>

- **Training Quests**: Campo de Treino, Defensor da Alma
- **Mid-Level Content**: Benção de Deus, Jardim de Deus, Equilíbrio da Força
- **Advanced Quests**: Ressureição do Cavaleiro Negro, Hidra Imortal
- **End-Game**: Início da Infelicidade, Desbloqueio de capa 355
- Detailed quest steps, NPCs, coordinates, rewards, and strategies

📁 **40 images** including quest banners, item icons, and reward previews

</details>

### 📰 [Wikipedia - Game Overview](sources/wikipedia_with_your_destiny/data/articles/markdown/)

<details>
<summary>Encyclopedia article with:</summary>

- Game history and publisher information
- Official release timeline (May 2003 - Present)
- Core gameplay mechanics and features
- Regional variations (Global, Korea, Brazil, Malaysia, Philippines)

</details>

## 🏗️ Project Structure

```
wyd/
├── README.md                        # This file
├── llms.txt                         # Page index for AI agents
├── llms-full.txt                    # Whole knowledge base in one file
├── wiki/                            # Curated knowledge base ⭐
│   ├── README.md                    # Categories and canon labels
│   └── <category>/<page>.md         # lore, classes, quests, maps, items...
├── scripts/kb/                      # Builds wiki/ from sources/
├── Gemfile                          # Ruby dependencies
└── sources/                         # All scraped content
    ├── feedback_kersef/             # WYD FAQ (feedback.kersef.com)
    │   ├── scripts/                 # Ruby automation scripts
    │   │   ├── *.rb                 # Scripts in ruyby
    │   └── data/
    │       ├── articles/            # 78 original HTML files
    │       │   └── markdown/        # 78 Markdown files ⭐
    │       └── images/              # 423 images
    │
    ├── raidhut_quests/              # Raid Hut Quest Guide
    │   └── data/
    │       ├── articles/            # Original HTML
    │       │   └── markdown/        # Quest guide Markdown ⭐
    │       └── images/              # 40 images
    │
    └── wikipedia_with_your_destiny/ # Wikipedia Article
        └── data/
            └── articles/            # Original HTML
                └── markdown/        # Wikipedia Markdown ⭐
```

## 🚀 Quick Start

### Prerequisites

- Ruby 3.x
- Bundler

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/wyd.git
cd wyd

# Install dependencies
bundle install
```

### Reading the Documentation

Start at [`wiki/README.md`](wiki/README.md) and browse by category. The raw scraped copies stay under `sources/*/data/articles/markdown/`.

## 🛠️ Technology Stack

- **Language**: Ruby 3.x
- **Web Scraping**: Capybara 3.40, Selenium WebDriver 4.16
- **HTML Parsing**: Nokogiri 1.16
- **Conversion**: markitdown (HTML to Markdown)
- **Browser**: Headless Chrome via ChromeDriver

## 📝 Contributing

This is an archival and documentation project. If you have additional WYD resources, historical information, or corrections, please open an issue or submit a pull request.

## 📄 License

- **Code**: MIT License
- **Documentation**: Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)
- **Game Content**: All game content, images, and trademarks belong to JoyImpact Co., Ltd. and respective publishers

## 🔗 Official Links

- **Global Server**: https://wydglobal.raidhut.com/
- **FAQ & Guides**: https://feedback.kersef.com/
- **Wikipedia**: https://en.wikipedia.org/wiki/With_Your_Destiny
- **Developer**: JoyImpact Co., Ltd.

## 📅 Last Updated

November 2025

---

**Disclaimer**: This is a fan-made documentation project. We are not affiliated with JoyImpact Co., Ltd., Raid Hut, or any official WYD publishers. All content is used for educational and archival purposes.
