# Source discovery

You maintain `sources/registry.yml`, the list of every known source about the MMORPG With Your
Destiny (WYD). Brazilian sources matter most, since the game was mostly played in Brazil.
Search the web for sources the registry does not have yet, and for changes to the ones it has.

## Look for

- Official news: Raid Hut (wydglobal.raidhut.com), JoyImpact, WYD M (mobile).
- Fan blogs, wikis (Fandom), forums (WebCheats, RaGEZONE) and YouTube channels or videos about WYD
  lore, quests, items, classes or history.
- Private servers, active or newly opened, especially ones that publish news or patch notes with
  new quests, items, maps or story. Server lists such as wydserver.com and the WebCheats
  "WYD Servidores Privados" board announce new ones.
- Archived copies of old official sites on the Wayback Machine.

Search in Portuguese and in English, for example "WYD servidor privado 2026", "With Your Destiny
história", "WYD quest guia", "WYD lore Kersef".

## Update the registry

- Add each new source as a new entry at the end of `sources:` with the same fields as the others:
  `id` (unique snake_case), `name`, `url`, `kind`, `canon` (`official`, `community` or
  `private-server`), `language`, `status`, `trust` (1-5), `covers`, `notes` and `verified` (what
  you actually opened or only saw in search results, with today's date).
- Add a `fetch` block with `enabled: true` only when you are confident the config works, such as
  a Blogger feed (`<blog>/feeds/posts/default?alt=rss&max-results=500` with `driver: feed`) or a
  page you opened and saw. Otherwise leave `fetch` out.
- For existing entries, update only `status` (for example to `offline`) and `notes` when you have
  evidence. Never remove an entry.
- Only list URLs you actually saw. Never guess a URL.
- Edit nothing outside `sources/registry.yml` except the summary below.

## Finish

1. Check that the file still parses: `ruby -ryaml -e 'YAML.load_file("sources/registry.yml")'`.
2. Write `build/pipeline/summary.md` in English: sources added (one line each on why they matter),
   sources whose status changed, and searches that found nothing new.
