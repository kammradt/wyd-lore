# Weekly knowledge base update

You maintain `wiki/`, a Brazilian Portuguese knowledge base about the MMORPG With Your Destiny (WYD).
The fetch step just archived new and changed source articles. Your job is to fold what they add into
the wiki, with citations, so a human can review the result as a pull request.

## Inputs

- `build/pipeline/changes.yml`: the new or changed items. Each has `source` (an id in
  `sources/registry.yml`), `canon`, `status` (`new` or `changed`), `url`, `title` and `archive`
  (the archived Markdown copy to read).
- `sources/registry.yml`: what each source is and how much to trust it (`trust` 1-5).
- `wiki/`: the current pages. `llms.txt` lists every page with its summary, which is the fastest way
  to find the page a fact belongs to. `grep -ril` over `wiki/` finds the rest.

## What to do for each item

1. Read the archived copy. Skip it, and note why, when it adds nothing to the lore, history,
   quests, items, maps, classes, systems or events of the game: ads, server-status notices, account
   or billing help, giveaways with no game content, near-duplicates of what a page already says,
   or text you cannot understand.
2. Otherwise decide where the information belongs:
   - **Update an existing page** when the topic already has one. Add the new facts in the right
     section, keep everything that is already there, and add the item to the page's `sources`.
   - **Create a page** when the topic is new. Use the category folder that fits (see
     `scripts/kb/categories.yml`) and a short Portuguese kebab-case file name without accents.
3. Write in Brazilian Portuguese, in an encyclopedic tone, keeping game names exactly as the game
   writes them (Kersef, Armia, Noatun, Hekalotia, Akelonia, Arch, Celestial). Translate
   English sources into Portuguese and set `translated_from: en` in the header.

## Page format (enforced by `ruby scripts/kb/check.rb`)

```yaml
---
title: Título da página
summary: Uma ou duas frases dizendo o que a página cobre.
category: quests            # must match the folder
tags: [quest, armia]        # Portuguese, lowercase kebab-case, no accents
canon: official             # official | community | private-server, or a list when sources mix
language: pt-BR
sources:
- name: Nome da fonte (from the registry)
  title: Título do artigo de origem
  url: https://...
  archive: sources/<id>/data/articles/markdown/<slug>.md
updated: 'YYYY-MM-DD'       # today
---

# Título da página

> O mesmo resumo do cabeçalho.

...conteúdo...

## Fontes

- [Título do artigo](url), Nome da fonte. Cópia arquivada: [arquivo.md](../../sources/...)
```

## Rules

- Official sources win. When a community source contradicts an official one, keep the official
  version and mention the other as "Segundo <fonte>, ...". Never delete official content.
- Content from private servers (`canon: private-server`) goes only in `wiki/servidores/`, one page
  per server, never mixed into the other categories.
- Keep `canon` honest: a page that gains a community source next to official ones lists both.
- Images: reuse the archived images with relative links (`../../sources/<id>/data/images/...`).
- Game files belong to JoyImpact: quote at most a few lines of in-game text.
- Do not edit anything under `sources/` or `scripts/`, and do not edit `llms.txt`,
  `llms-full.txt` or any `README.md` in `wiki/` by hand.

## Finish

1. Run `ruby scripts/kb/build_indexes.rb` and then `ruby scripts/kb/check.rb`. Fix every problem
   it reports and run it again until it prints `OK`.
2. Write `build/pipeline/summary.md` in English for the pull request description, with three
   short lists: pages created, pages updated (one line each on what changed), and items skipped
   with the reason.
