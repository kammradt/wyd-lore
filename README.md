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

- [x] Verify if all images are correctly linked in markdown files (`ruby scripts/kb/check.rb`)


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

The curated knowledge base lives in [`wiki/`](wiki/README.md): **95 pages in Brazilian Portuguese**, organized by topic (lore, história, classes, progressão, quests, mapas, itens, sistemas, PvP, NPCs, eventos). Game content is Portuguese only; code, scripts and repo docs are in English.

- **For humans**: start at [`wiki/README.md`](wiki/README.md). Each category folder has a README index with a one-line summary per page.
- **For AI agents**: [`llms.txt`](llms.txt) lists every page with its summary, and [`llms-full.txt`](llms-full.txt) has the whole knowledge base in one file.
- **Structured data**: [`data/`](data/README.md) has quests, maps and NPCs as YAML, extracted from the pages, for agents that need fields instead of prose.
- **Every page has a YAML header**: `title`, `summary`, `category`, `tags`, `canon`, `language`, `sources` (original URL plus the archived copy) and `updated`. The `canon` label is one of:
  - `official`: published by the developer or a publisher (JoyImpact, HanbitSoft, Raid Hut), or text from the game client
  - `community`: third-party writing such as Wikipedia, fan blogs, forums and videos
  - `private-server`: content created by private servers, kept in [`wiki/servidores/`](wiki/servidores/README.md) and out of canon

### Scripts (`scripts/kb/`)

| Script | What it does |
| --- | --- |
| `build_wiki.rb` | Initial migration: creates pages from the archived sources using `manifest.yml` (which source articles feed which page) and `metadata.yml` (title, summary, tags). Skips pages that already exist unless named or `--force`. |
| `build_indexes.rb` | Regenerates `wiki/README.md`, every category README, `llms.txt` and `llms-full.txt` from the page headers. Run it after any page change. |
| `check.rb` | Validates headers, categories, canon labels and every relative link and image. |

```bash
ruby scripts/kb/build_indexes.rb && ruby scripts/kb/check.rb
```

After the migration the pages in `wiki/` are the source of truth: edit them directly (by hand or through the update pipeline), never by re-running the migration.

## 🌐 Wiki Site

The same `wiki/` pages are published as a searchable website built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/): Portuguese search, light and dark themes, tag pages, and a canon/sources line under each title. It is planned for **https://kammradt.github.io/wyd-lore/**.

- [`.github/workflows/site.yml`](.github/workflows/site.yml) checks the knowledge base, builds the site on every push to `main`, and deploys it to GitHub Pages. Pull requests only build it.
- One-time setup: **Settings → Pages → Build and deployment → Source: GitHub Actions**. A private repository needs a paid GitHub plan for Pages.

```bash
pip install -r site/requirements.txt
ruby scripts/site/build.rb --serve   # preview at http://127.0.0.1:8000
```

## 🔄 Sources and Update Pipeline

### Source registry

[`sources/registry.yml`](sources/registry.yml) lists **90 known sources**, ranked by trust (5 = official primary source, 1 = speculation) and labeled with the canon their pages must carry. It covers official sites and FAQs, archived official sites on the Wayback Machine, fan blogs, Fandom wikis, forums, videos, private servers, server lists, and open-source emulators that contain the game's own text. A readable version is generated at [`wiki/fontes.md`](wiki/fontes.md).

**Game text or blogs?** Both, for different jobs. Text from the game client (NPC dialogue, item names, quest messages) is the authoritative source for names and quotes. It is sparse, though: short lines, no continuous story. The official FAQ articles and fan blogs carry the narrative, the history and the player memory. Pages cite the game text to verify names and quotes, and use blogs for story and context, labeled `community`. Private-server news is kept as a separate post-canon layer in `wiki/servidores/`. Game files belong to JoyImpact, so the wiki quotes short excerpts and the repo never stores the files themselves.

### Weekly pipeline

[`.github/workflows/update.yml`](.github/workflows/update.yml) runs every Monday, and on demand from the Actions tab:

1. **Fetch** ([`scripts/pipeline/fetch.rb`](scripts/pipeline/fetch.rb)). For every source with an enabled `fetch` block, a driver lists its items and archives the new or changed ones under `sources/<id>/`. Drivers cover RSS/Atom feeds (Blogger, WordPress, Raid Hut news), listing pages (the Kersef FAQ), MediaWiki (Fandom), Wayback Machine snapshots and fixed URL lists. Each source has an `index.yml` with content hashes, so unchanged items are skipped.
2. **Update.** Claude reads the new items and folds them into `wiki/` following [`scripts/pipeline/prompts/update.md`](scripts/pipeline/prompts/update.md): it updates existing pages or creates new ones, cites every source and keeps the canon labels honest. It then rebuilds the indexes and runs `check.rb`.
3. **Discover.** Claude searches the web for new blogs, wikis, videos and private servers following [`scripts/pipeline/prompts/discover.md`](scripts/pipeline/prompts/discover.md), and adds them to the registry.

Each run opens a pull request (`pipeline/weekly-update` and `pipeline/source-discovery`), so nothing reaches `main` without review.

**One-time setup:**
- Add the repository secret `ANTHROPIC_API_KEY` (Settings → Secrets and variables → Actions). Without it the fetch still runs, and the PR carries only the archived sources.
- Enable **Settings → Actions → General → Allow GitHub Actions to create and approve pull requests**.

```bash
gem install nokogiri reverse_markdown
ruby scripts/pipeline/fetch.rb --source raidhut_wydglobal_rss --limit 5   # try one source locally
```

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
├── data/                            # quests.yml, maps.yml, npcs.yml (structured data from wiki/)
├── scripts/kb/                      # Builds indexes and validates wiki/
├── scripts/pipeline/                # Weekly fetch + AI update prompts
├── scripts/site/ + site/            # Wiki site (MkDocs Material)
├── Gemfile                          # Ruby dependencies
└── sources/                         # All scraped content + registry.yml
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

October 2026

---

**Disclaimer**: This is a fan-made documentation project. We are not affiliated with JoyImpact Co., Ltd., Raid Hut, or any official WYD publishers. All content is used for educational and archival purposes.
