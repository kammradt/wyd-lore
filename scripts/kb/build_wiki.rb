# frozen_string_literal: true

# Builds the wiki/ knowledge base from the archived sources in sources/.
#
# The archive in sources/ is never modified. This script reads it, strips site
# chrome (menus, footers, comment boxes), merges sources that describe the same
# thing into one page, and writes wiki/<category>/<slug>.md with a YAML header,
# plus category indexes and llms.txt / llms-full.txt for agents.
#
# It is meant for the initial migration and for rebuilding pages that nobody
# has edited by hand yet. Pass page paths (e.g. quests/training-camp) to rebuild
# only those; with no arguments every page in manifest.yml is rebuilt.
#
#   ruby scripts/kb/build_wiki.rb
#   ruby scripts/kb/build_wiki.rb quests/training-camp maps/armia

require 'yaml'
require 'date'
require 'fileutils'

Encoding.default_external = Encoding::UTF_8

ROOT = File.expand_path('../..', __dir__)
KB_DIR = File.join(ROOT, 'scripts/kb')
WIKI = File.join(ROOT, 'wiki')
TODAY = Date.today.iso8601

CATEGORIES = {
  'lore' => ['Lore', 'Lore', 'Mitologia, deuses e a história do mundo de Kersef.'],
  'history' => ['História do jogo', 'Game history', 'Publicadoras, versões e linha do tempo do WYD no mundo real.'],
  'classes' => ['Classes', 'Classes', 'As classes jogáveis e suas skills.'],
  'progression' => ['Progressão', 'Progression', 'Evolução do personagem: Mortal, Arch, Celestial, Sub-Celestial.'],
  'quests' => ['Quests', 'Quests', 'Quests por faixa de level, com etapas, NPCs e recompensas.'],
  'maps' => ['Mapas e dungeons', 'Maps and dungeons', 'Regiões, cidades e dungeons de Kersef.'],
  'items' => ['Itens', 'Items', 'Armas, armaduras, acessórios e materiais.'],
  'systems' => ['Sistemas', 'Game systems', 'Mecânicas do jogo: refinação, guildas, reinos, montarias e mais.'],
  'pvp' => ['PvP', 'PvP', 'Guerras de reino, arenas e combate entre jogadores.'],
  'npcs' => ['NPCs', 'NPCs', 'Personagens não jogáveis e o que oferecem.'],
  'events' => ['Eventos', 'Events', 'Invasões e eventos do servidor.'],
  'support' => ['Suporte', 'Support', 'Ajuda técnica e de conta. Não é conteúdo do jogo.'],
  'servers' => ['Servidores privados', 'Private servers', 'Conteúdo de servidores privados, separado do canon oficial.']
}.freeze

CANON = {
  'official' => 'Publicado pela desenvolvedora ou publicadora oficial (JoyImpact, Raid Hut).',
  'community' => 'Escrito por terceiros: Wikipedia, blogs e fóruns de fãs.',
  'private-server' => 'Conteúdo criado por servidores privados; não faz parte do canon oficial.'
}.freeze

SOURCES = {
  'kersef' => {
    name: 'FAQ WYD Global (feedback.kersef.com)', short: 'FAQ WYD Global',
    canon: 'official', language: 'pt-BR',
    site: 'https://feedback.kersef.com',
    images: 'sources/feedback_kersef/data/images'
  },
  'raidhut' => {
    name: 'Guia Quest Mortal (Raid Hut)', short: 'Raid Hut',
    canon: 'official', language: 'pt-BR',
    site: 'https://wydglobal.raidhut.com',
    url: 'https://wydglobal.raidhut.com/',
    archive: 'sources/raidhut_quests/data/articles/markdown/quests_mortais.md',
    images: 'sources/raidhut_quests/data/images'
  },
  'wikipedia' => {
    name: 'Wikipedia: With Your Destiny', short: 'Wikipedia',
    canon: 'community', language: 'en',
    site: 'https://en.wikipedia.org',
    url: 'https://en.wikipedia.org/wiki/With_Your_Destiny',
    archive: 'sources/wikipedia_with_your_destiny/data/articles/markdown/with_your_destiny.md'
  }
}.freeze

# A section of an archived source, cleaned up and ready to place in a page.
Section = Struct.new(:source, :title, :body, :url, :archive, keyword_init: true)

def read(path) = File.read(File.join(ROOT, path), encoding: "UTF-8")

def absolutize_links(text, site)
  text.gsub(%r{\]\(/(?!/)}, "](#{site}/").gsub(%r{\]\(//}, '](https://')
end

def relink_images(text, images_dir)
  return text unless images_dir

  text.gsub('](../../images/', "](../../#{images_dir}/")
end

def tidy(text)
  text.gsub(/\n{3,}/, "\n\n").strip
end

def kersef_section(id)
  archive = Dir.glob(File.join(ROOT, "sources/feedback_kersef/data/articles/markdown/#{id}-*.md")).first
  raise "kersef article #{id} not found" unless archive

  archive = archive.delete_prefix("#{ROOT}/")
  lines = read(archive).lines
  start = lines.index { _1.start_with?('# ') }
  heading = lines[start]
  title = heading[/^# \[(.*)\]\(/, 1] || heading.delete_prefix('# ').strip
  path = heading[/\]\((\/[^)]+)\)/, 1]
  body = lines[(start + 1)..].take_while { _1 !~ /(This article was helpful|Is this article helpful)/ }.join
  src = SOURCES['kersef']
  body = relink_images(absolutize_links(body, src[:site]), src[:images])
  Section.new(source: 'kersef', title: title, body: tidy(body), url: "#{src[:site]}#{path}", archive: archive)
end

def raidhut_sections
  @raidhut_sections ||= begin
    src = SOURCES['raidhut']
    lines = read(src[:archive]).lines
    anchors = read(src[:archive]).scan(/\]\(#([a-z0-9-]+)\)/).flatten
    starts = lines.each_index.select { |i| lines[i + 1]&.match?(/^Level \d+ ?~ ?Level \d+\s*$/) && lines[i] !~ /^Level/ }
    stop = lines.index { _1.start_with?('## Quest Item Icons') }
    raise "expected #{anchors.size} quests, found #{starts.size}" unless starts.size == anchors.size

    starts.each_with_index.to_h do |s, n|
      finish = (starts[n + 1] || stop) - 1
      level = lines[s + 1].strip.gsub(/\s*~\s*/, ' ~ ')
      body = "**#{level}**\n\n#{lines[(s + 2)..finish].join}".sub(/(\s*---\s*)+\z/, '')
      body = relink_images(absolutize_links(body, src[:site]), src[:images])
      [anchors[n], Section.new(source: 'raidhut', title: lines[s].strip, body: tidy(body),
                               url: "#{src[:url]}##{anchors[n]}", archive: src[:archive])]
    end
  end
end

def wikipedia_section
  src = SOURCES['wikipedia']
  text = read(src[:archive])
  body = text[/^\| With Your Destiny \| \|$.*?(?=^!\[\]\(https:\/\/en\.wikipedia\.org\/wiki\/Special:CentralAutoLogin)/m]
  body = body.lines.reject { _1.match?(/^\[\[edit\]\(/) }.join
  body = absolutize_links(body, src[:site])
  Section.new(source: 'wikipedia', title: 'With Your Destiny', body: tidy(body), url: src[:url], archive: src[:archive])
end

def section_for(ref)
  kind, key = ref.split(':', 2)
  case kind
  when 'kersef' then kersef_section(key)
  when 'raidhut' then raidhut_sections.fetch(key) { raise "unknown raidhut quest #{key}" }
  when 'wikipedia' then wikipedia_section
  else raise "unknown source ref #{ref}"
  end
end

# Pushes every heading down so the page title stays the only H1.
def demote(text, levels)
  text.gsub(/^(#+) /) { "#{'#' * [Regexp.last_match(1).size + levels, 6].min} " }
end

def frontmatter(category, meta, sections)
  canon = sections.map { SOURCES[_1.source][:canon] }.uniq
  data = {
    'title' => meta.fetch('title'),
    'title_en' => meta.fetch('title_en'),
    'summary_en' => meta.fetch('summary_en'),
    'category' => category,
    'tags' => meta.fetch('tags'),
    'canon' => canon.size == 1 ? canon.first : canon,
    'language' => sections.map { SOURCES[_1.source][:language] }.uniq.join(', '),
    'sources' => sections.map do |s|
      { 'name' => SOURCES[s.source][:name], 'title' => s.title, 'url' => s.url, 'archive' => s.archive }
    end,
    'updated' => TODAY
  }
  data.to_yaml(line_width: -1)
end

def render_page(category, meta, sections)
  out = +"#{frontmatter(category, meta, sections)}---\n\n"
  out << "# #{meta['title']}\n\n"
  out << "> **#{meta['title_en']}.** #{meta['summary_en']}\n\n"
  if sections.size == 1
    out << demote(sections.first.body, 1) << "\n\n"
  else
    sections.each do |s|
      out << "## #{s.title} (#{SOURCES[s.source][:short]})\n\n" << demote(s.body, 2) << "\n\n"
    end
  end
  out << "## Fontes\n\n"
  sections.each do |s|
    archive_link = "../../#{s.archive}"
    out << "- [#{s.title}](#{s.url}), #{SOURCES[s.source][:name]}. Cópia arquivada: [#{File.basename(s.archive)}](#{archive_link})\n"
  end
  out
end

def page_header(path)
  YAML.safe_load(File.read(path).split(/^---\s*$/, 3)[1], permitted_classes: [Date])
end

def write_indexes(manifest)
  all = []
  CATEGORIES.each do |category, (name, name_en, blurb)|
    dir = File.join(WIKI, category)
    FileUtils.mkdir_p(dir)
    pages = (manifest[category] || {}).keys.map do |slug|
      path = File.join(dir, "#{slug}.md")
      [slug, page_header(path)] if File.exist?(path)
    end.compact
    all << [category, name, name_en, blurb, pages]
    next if category == 'servers'

    out = +"# #{name}\n\n*#{name_en}.* #{blurb}\n\n| Página | English | Resumo |\n| --- | --- | --- |\n"
    pages.each do |slug, h|
      out << "| [#{h['title']}](#{slug}.md) | #{h['title_en']} | #{h['summary_en'].gsub('|', '\\|')} |\n"
    end
    File.write(File.join(dir, 'README.md'), out)
  end

  readme = +"# Base de conhecimento WYD\n\n"
  readme << "Páginas organizadas por tema. Cada página começa com um cabeçalho YAML que lista título em inglês, resumo, tags, " \
            "fontes e o nível de canon. O arquivo original de cada fonte continua intacto em [`sources/`](../sources/).\n\n"
  readme << "## Categorias\n\n"
  all.each { |c, n, ne, b, p| readme << "- [#{n}](#{c}/README.md) (#{ne}, #{p.size} páginas): #{b}\n" }
  readme << "\n## Canon\n\n"
  CANON.each { |k, v| readme << "- `#{k}`: #{v}\n" }
  File.write(File.join(WIKI, 'README.md'), readme)
  all
end

def write_llms(all)
  txt = +"# WYD Lore\n\n"
  txt << "> Knowledge base for the MMORPG With Your Destiny (WYD, JoyImpact, 2003): lore of Kersef, classes, quests, " \
         "maps, items, systems and game history. Pages are Markdown, mostly in Brazilian Portuguese, each with a YAML " \
         "header carrying title_en, summary_en, tags, sources and a canon label (official, community, private-server).\n\n"
  txt << "Every page lists its sources; archived copies of each source live under sources/. " \
         "llms-full.txt has every page in one file.\n"
  full = +"# WYD Lore: full text\n\n"
  all.each do |category, _name, name_en, _blurb, pages|
    next if pages.empty?

    txt << "\n## #{name_en}\n\n"
    pages.each do |slug, h|
      rel = "wiki/#{category}/#{slug}.md"
      txt << "- [#{h['title_en']}](#{rel}): #{h['summary_en']}\n"
      full << "\n\n<!-- #{rel} -->\n\n" << File.read(File.join(ROOT, rel))
    end
  end
  File.write(File.join(ROOT, 'llms.txt'), txt)
  File.write(File.join(ROOT, 'llms-full.txt'), full.strip + "\n")
end

manifest = YAML.load_file(File.join(KB_DIR, 'manifest.yml'))
metadata = YAML.load_file(File.join(KB_DIR, 'metadata.yml'))
only = ARGV.to_a

manifest.each do |category, pages|
  pages.each do |slug, refs|
    key = "#{category}/#{slug}"
    next unless only.empty? || only.include?(key)

    meta = metadata.fetch(key) { raise "missing metadata for #{key}" }
    FileUtils.mkdir_p(File.join(WIKI, category))
    File.write(File.join(WIKI, "#{key}.md"), render_page(category, meta, refs.map { section_for(_1) }))
  end
end

all = write_indexes(manifest)
write_llms(all)
puts "Built #{all.sum { _1[4].size }} pages in #{all.count { _1[4].any? }} categories"
