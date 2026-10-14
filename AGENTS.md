# Guide for AI agents

This repo is a knowledge base about the MMORPG With Your Destiny (WYD). Read this before changing anything.

## Rules

- **Language:** all game and lore content (`wiki/`, `data/`) is in Brazilian Portuguese. Code, scripts, commit messages and repo docs are in English.
- **One branch:** work from `main`. Open a pull request for every change and delete the branch after it merges.
- **Sources stay raw:** never edit files under `sources/*/data/`; they are the archived originals.
- **Cite everything:** every wiki page lists its sources in the YAML header, each with the original `url` and the `archive` copy under `sources/`.
- **Keep canon honest:** `canon` is `official`, `community` or `private-server`. Private-server content goes only in `wiki/servidores/`. When sources disagree, show both versions and say which source says what.
- **No scheduled scraping:** `.github/workflows/update.yml` runs only by hand. Don't add a schedule unless the owner asks.

## Layout

| Path | What it is |
| --- | --- |
| `wiki/<categoria>/<slug>.md` | The pages. Categories and their order are in `scripts/kb/categories.yml`. |
| `wiki/README.md`, `wiki/*/README.md`, `wiki/fontes.md` | Generated indexes. Hand notes in a category README go after `<!-- notas -->`. |
| `llms.txt`, `llms-full.txt` | Generated page index and full text for agents. |
| `data/` | Quests, maps and NPCs as YAML, extracted from the pages. Update them when the pages change. |
| `sources/registry.yml` | Every known source, ranked by trust, with optional `fetch` configs. |
| `sources/<id>/` | Archived originals (HTML, Markdown, images) per source. |
| `scripts/kb/` | `build_indexes.rb`, `check.rb`, and the one-time migration `build_wiki.rb`. |
| `scripts/pipeline/` | `fetch.rb` and the Claude prompts for the update and discovery jobs. |
| `scripts/site/`, `site/` | The MkDocs Material site, deployed to https://kammradt.github.io/wyd-lore/ on merge. |

## Local asset sources

Game assets are not in this repo yet, but at least one full source exists on the owner's machine:

- `wyd-client` (clone of https://github.com/acgfbr/wyd-client, a web port of the classic client), kept at `/home/kamm/repos/wyd-client`. Under `public/game-data/classic/` it has item and skill icon atlases (`ui/`), 3D models, animations and textures for players, monsters, mounts and map objects (`.msh`, `.msa`, `.ani`, `.bon`, `.dds`), the 111 maps, item, skill and NPC data, and audio. `docs/matriz-cobertura-classico.md` there has the full inventory.

When a page or tool needs these assets, copy or link them as that use requires.

## Page header

```yaml
title: Deuses
summary: Uma ou duas frases sobre a página.
category: lore            # must match the folder
tags: [deuses, lore]
canon: official           # or a list, e.g. [official, community]
language: pt-BR
sources:
- name: FAQ WYD Global (feedback.kersef.com)
  title: História
  url: https://...
  archive: sources/feedback_kersef/data/articles/markdown/20364-historia.md
updated: 2026-10-13
```

The body starts with `# <title>`. File names are kebab-case without accents.

## After editing pages

```bash
LANG=C.UTF-8 ruby scripts/kb/build_indexes.rb   # rebuild indexes and llms files
LANG=C.UTF-8 ruby scripts/kb/check.rb           # must print OK
pip install -r site/requirements.txt && ruby scripts/site/build.rb --build   # optional: strict site build
```

CI runs the same check and site build on every pull request.
