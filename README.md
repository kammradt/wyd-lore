# WYD (With Your Destiny) Documentation Project

> A comprehensive documentation and scraping project for the MMORPG "With Your Destiny" (WYD)

[![License](https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![Ruby](https://img.shields.io/badge/ruby-3.x-red.svg)](https://www.ruby-lang.org/)

## 📖 About

This project aims to preserve and organize the history, lore, and game mechanics of **With Your Destiny (WYD)**, a fantasy MMORPG developed by JoyImpact Co., Ltd. Through automated web scraping and careful curation, we've compiled guides, quest information, and historical records from various sources.

## 🎮 About With Your Destiny (WYD)

**With Your Destiny** is a Free-to-play Fantasy MMORPG set in the world of **Kersef**, featuring:

- **Lore**: Epic story of gods (Yetzirah, Tzfah) and their conflict affecting humanity
- **Kingdoms**: Hekalotia (Blue) vs Akeronia (Red) in eternal rivalry
- **Progression**: From Mortal → Celestial → Sub-Celestial → Arch (1500+ levels)
- **Classes**: 4 unique classes with 150+ customizable skills
- **PvP**: Massive battles supporting up to 1000 simultaneous players
- **Content**: Dungeons, quests, guild wars, kingdom battles, mounts, and more

**Publisher History:**
- Original: HanbitSoft Inc. (2003)
- Current: Raid Hut Ltd. (2019-present, Global) & JoyImpact (Korea)


## 📚 Documentation Sources

We've collected and scrapped information form several sources.

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

All documentation is in Markdown format with local images. Simply open any `.md` file in the `markdown/` directories:

```bash
# Game guides (78 files)
open sources/feedback_kersef/data/articles/markdown/

# Quest guide
open sources/raidhut_quests/data/articles/markdown/quests_mortais.md

# Wikipedia article
open sources/wikipedia_with_your_destiny/data/articles/markdown/with_your_destiny.md
```

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
