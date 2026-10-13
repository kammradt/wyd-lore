# frozen_string_literal: true

# Regenerates every index from the page headers in wiki/:
#   wiki/README.md, wiki/<category>/README.md, llms.txt and llms-full.txt.
#
# Run it after adding or editing pages. It never touches the pages themselves.
#
#   ruby scripts/kb/build_indexes.rb

require_relative 'lib'

def table_cell(text) = text.to_s.gsub('|', '\\|').gsub("\n", ' ')

categories = KB.categories
pages = KB.pages.group_by { |path, _h, _b| path.split('/').first }
sorted = ->(list) { (list || []).sort_by { |_p, h, _b| h['title'].downcase.unicode_normalize(:nfkd) } }

categories.each do |key, cat|
  dir = File.join(KB::WIKI, key)
  FileUtils.mkdir_p(dir)
  list = sorted.(pages[key])
  out = +"# #{cat['name']}\n\n#{cat['description']}\n\n"
  if list.empty?
    out << "Ainda não há páginas nesta categoria.\n"
  else
    out << "| Página | Resumo | Canon |\n| --- | --- | --- |\n"
    list.each do |path, h, _b|
      out << "| [#{table_cell(h['title'])}](#{File.basename(path)}) | #{table_cell(h['summary'])} | #{Array(h['canon']).join(', ')} |\n"
    end
  end
  readme = File.join(dir, 'README.md')
  # A category README may carry hand-written guidance below this marker; keep it.
  marker = "<!-- notas -->\n"
  out << "\n#{marker}#{File.read(readme).split(marker, 2)[1]}" if File.exist?(readme) && File.read(readme).include?(marker)
  File.write(readme, out)
end

total = pages.values.sum(&:size)
readme = +"# Base de conhecimento WYD\n\n"
readme << "#{total} páginas sobre With Your Destiny, organizadas por tema. Cada página começa com um cabeçalho YAML " \
          "com título, resumo, tags, fontes e o nível de canon. As cópias originais de cada fonte ficam intactas em " \
          "[`sources/`](../sources/)#{File.exist?(File.join(KB::ROOT, "sources/registry.yml")) ? ", e o registro de fontes conhecidas está em [`sources/registry.yml`](../sources/registry.yml)" : ""}.\n\n"
readme << "## Categorias\n\n"
categories.each do |key, cat|
  readme << "- [#{cat['name']}](#{key}/README.md) (#{(pages[key] || []).size}): #{cat['description']}\n"
end
readme << "\nVeja também a lista de [fontes](fontes.md) conhecidas e o que cada uma cobre.\n" if File.exist?(File.join(KB::ROOT, "sources/registry.yml"))
readme << "\n## Canon\n\n"
KB.canon_labels.each { |k, v| readme << "- `#{k}`: #{v}\n" }
File.write(File.join(KB::WIKI, 'README.md'), readme)

# wiki/fontes.md: the source registry, readable by people.
registry_path = File.join(KB::ROOT, 'sources/registry.yml')
if File.exist?(registry_path)
  registry = YAML.load_file(registry_path)
  kinds = { 'official' => 'Fontes oficiais', 'community' => 'Fontes da comunidade',
            'private-server' => 'Servidores privados' }
  fontes = +"# Fontes\n\nTodas as fontes conhecidas sobre With Your Destiny, ordenadas por confiança " \
            "(5 = fonte oficial primária, 1 = especulação). As marcadas com ✔ são coletadas toda semana pelo " \
            "pipeline de atualização. A lista completa, com notas de pesquisa, está em " \
            "[`sources/registry.yml`](../sources/registry.yml).\n"
  kinds.each do |canon, title|
    list = registry['sources'].select { _1['canon'] == canon }
    next if list.empty?

    fontes << "\n## #{title}\n\n| Fonte | Tipo | Confiança | Coleta | Conteúdo |\n| --- | --- | --- | --- | --- |\n"
    list.each do |s|
      collected = s.dig('fetch', 'enabled') ? '✔' : (s['archive'] ? 'arquivada' : '')
      fontes << "| [#{table_cell(s['name'])}](#{s['url']}) | #{s['kind']} | #{s['trust']} | #{collected} | " \
                "#{table_cell(s['covers'].to_s[0, 220])}#{'…' if s['covers'].to_s.size > 220} |\n"
    end
  end
  File.write(File.join(KB::WIKI, 'fontes.md'), fontes)
end

llms = +"# WYD Lore\n\n"
llms << "> Base de conhecimento sobre o MMORPG With Your Destiny (WYD, JoyImpact, 2003): lore de Kersef, classes, " \
        "quests, mapas, itens, sistemas e história do jogo. Todo o conteúdo está em português do Brasil.\n\n"
llms << "Cada página é Markdown com um cabeçalho YAML: `title`, `summary`, `category`, `tags`, `canon` " \
        "(official, community ou private-server), `language` e `sources` (URL original e cópia arquivada em sources/). " \
        "Use `canon` para separar o conteúdo oficial do conteúdo de fãs e de servidores privados. " \
        "O arquivo llms-full.txt traz todas as páginas em um só arquivo.\n"
full = +"# WYD Lore: texto completo\n"
categories.each do |key, cat|
  list = sorted.(pages[key])
  next if list.empty?

  llms << "\n## #{cat['name']}\n\n"
  list.each do |path, h, body|
    rel = "wiki/#{path}"
    llms << "- [#{h['title']}](#{rel}): #{h['summary']}\n"
    full << "\n\n<!-- #{rel} -->\n\n" << KB.render_page(h, body)
  end
end
File.write(File.join(KB::ROOT, 'llms.txt'), llms)
File.write(File.join(KB::ROOT, 'llms-full.txt'), "#{full.strip}\n")
puts "Indexed #{total} pages in #{pages.size} categories"
