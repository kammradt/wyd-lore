# frozen_string_literal: true

# Creates wiki/ pages from the archived sources in sources/ (the initial migration).
#
# The archive in sources/ is never modified. For each page in manifest.yml this
# script reads the listed source articles, strips site chrome (menus, footers,
# comment boxes), merges several sources into one page when they describe the
# same thing, and writes wiki/<category>/<slug>.md with a YAML header taken from
# metadata.yml. Then it rebuilds the indexes.
#
# Pages that already exist are skipped, because after the migration the pages
# themselves are the source of truth (people and the update pipeline edit them).
# Name pages explicitly, or pass --force, to overwrite.
#
#   ruby scripts/kb/build_wiki.rb                          # create missing pages
#   ruby scripts/kb/build_wiki.rb quests/campo-de-treinamento   # rebuild one page
#   ruby scripts/kb/build_wiki.rb --force                  # rebuild every page

require_relative 'lib'

TODAY = Date.today.iso8601

SOURCES = {
  'kersef' => {
    name: 'FAQ WYD Global (feedback.kersef.com)', short: 'FAQ WYD Global',
    canon: 'official', site: 'https://feedback.kersef.com',
    images: 'sources/feedback_kersef/data/images'
  },
  'raidhut' => {
    name: 'Guia Quest Mortal (Raid Hut)', short: 'Raid Hut',
    canon: 'official', site: 'https://wydglobal.raidhut.com', url: 'https://wydglobal.raidhut.com/',
    archive: 'sources/raidhut_quests/data/articles/markdown/quests_mortais.md',
    images: 'sources/raidhut_quests/data/images'
  },
  'wikipedia' => {
    name: 'Wikipedia: With Your Destiny', short: 'Wikipedia',
    canon: 'community', site: 'https://en.wikipedia.org', url: 'https://en.wikipedia.org/wiki/With_Your_Destiny',
    archive: 'sources/wikipedia_with_your_destiny/data/articles/markdown/with_your_destiny.md',
    translation: 'sources/wikipedia_with_your_destiny/data/articles/markdown/with_your_destiny.pt-br.md'
  }
}.freeze

# A section of an archived source, cleaned up and ready to place in a page.
Section = Struct.new(:source, :title, :body, :url, :archive, keyword_init: true)

def read(path) = File.read(File.join(KB::ROOT, path))

def absolutize_links(text, site)
  text.gsub(%r{\]\(/(?!/)}, "](#{site}/").gsub(%r{\]\(//}, '](https://')
end

def relink_images(text, images_dir)
  return text unless images_dir

  text.gsub('](../../images/', "](../../#{images_dir}/")
end

def tidy(text) = text.gsub(/\n{3,}/, "\n\n").strip

def kersef_section(id)
  archive = Dir.glob(File.join(KB::ROOT, "sources/feedback_kersef/data/articles/markdown/#{id}-*.md")).first
  raise "kersef article #{id} not found" unless archive

  archive = archive.delete_prefix("#{KB::ROOT}/")
  lines = read(archive).lines
  start = lines.index { _1.start_with?('# ') }
  heading = lines[start]
  title = heading[/^# \[(.*)\]\(/, 1] || heading.delete_prefix('# ').strip
  path = heading[%r{\]\((/[^)]+)\)}, 1]
  body = lines[(start + 1)..].take_while { _1 !~ /(This article was helpful|Is this article helpful)/ }.join
  src = SOURCES['kersef']
  body = relink_images(absolutize_links(body, src[:site]), src[:images])
  Section.new(source: 'kersef', title: title, body: tidy(body), url: "#{src[:site]}#{path}", archive: archive)
end

def raidhut_sections
  @raidhut_sections ||= begin
    src = SOURCES['raidhut']
    text = read(src[:archive])
    lines = text.lines
    anchors = text.scan(/\]\(#([a-z0-9-]+)\)/).flatten
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

# The Wikipedia article is in English, so the page uses the Portuguese
# translation stored next to the archived copy.
def wikipedia_section
  src = SOURCES['wikipedia']
  body = read(src[:translation]).sub(/\A<!--.*?-->\s*/m, '')
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

def build_page(category, meta, sections)
  canon = sections.map { SOURCES[_1.source][:canon] }.uniq
  header = {
    'title' => meta.fetch('title'),
    'summary' => meta.fetch('summary'),
    'category' => category,
    'tags' => meta.fetch('tags'),
    'canon' => canon.size == 1 ? canon.first : canon,
    'language' => 'pt-BR',
    'sources' => sections.map do |s|
      { 'name' => SOURCES[s.source][:name], 'title' => s.title, 'url' => s.url, 'archive' => s.archive }
    end,
    'updated' => TODAY
  }
  header['translated_from'] = 'en' if sections.any? { SOURCES[_1.source][:translation] }

  body = +"# #{meta['title']}\n\n> #{meta['summary']}\n\n"
  if sections.size == 1
    body << demote(sections.first.body, 1) << "\n\n"
  else
    sections.each do |s|
      body << "## #{s.title} (#{SOURCES[s.source][:short]})\n\n" << demote(s.body, 2) << "\n\n"
    end
  end
  body << "## Fontes\n\n"
  sections.each do |s|
    body << "- [#{s.title}](#{s.url}), #{SOURCES[s.source][:name]}. " \
            "Cópia arquivada: [#{File.basename(s.archive)}](../../#{s.archive})\n"
  end
  KB.render_page(header, body)
end

force = ARGV.delete('--force')
only = ARGV.to_a
manifest = YAML.load_file(File.join(KB::DIR, 'manifest.yml'))
metadata = YAML.load_file(File.join(KB::DIR, 'metadata.yml'))
written = 0

manifest.each do |category, pages|
  pages.each do |slug, refs|
    key = "#{category}/#{slug}"
    path = File.join(KB::WIKI, "#{key}.md")
    next unless only.empty? ? (force || !File.exist?(path)) : only.include?(key)

    meta = metadata.fetch(key) { raise "missing metadata for #{key}" }
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, build_page(category, meta, refs.map { section_for(_1) }))
    written += 1
  end
end

puts "Wrote #{written} page(s)"
load File.join(KB::DIR, 'build_indexes.rb')
