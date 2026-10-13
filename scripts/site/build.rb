# frozen_string_literal: true

# Assembles the wiki site in build/site/ and, with --serve or --build, runs MkDocs on it.
#
# The docs directory mirrors wiki/ (so every relative link in the pages keeps
# working) plus the archived image folders the pages point to. Links to other
# repo files, such as the archived source articles, become GitHub links.
#
#   ruby scripts/site/build.rb            # assemble only
#   ruby scripts/site/build.rb --build    # assemble and run `mkdocs build --strict`
#   ruby scripts/site/build.rb --serve    # assemble and run `mkdocs serve`

require 'pathname'
require_relative '../kb/lib'

OUT = File.join(KB::ROOT, 'build/site')
DOCS = File.join(OUT, 'docs')
REPO_BLOB = 'https://github.com/kammradt/wyd-lore/blob/main'
CANON_NAMES = { 'official' => 'oficial', 'community' => 'comunidade', 'private-server' => 'servidor privado' }.freeze

# Rewrites links that leave wiki/ and are not copied images into GitHub links.
def relink(text, file_in_wiki)
  text.gsub(/(\]\()([^)\s]+)/) do
    prefix, link = Regexp.last_match(1), Regexp.last_match(2)
    next "#{prefix}#{link}" if link.match?(/\A(https?:|mailto:|#)/)

    target = File.expand_path(link.split('#').first, File.dirname(file_in_wiki))
    inside_wiki = target.start_with?("#{KB::WIKI}/")
    copied_image = target.include?('/data/images/')
    next "#{prefix}#{link}" if inside_wiki
    if copied_image
      # wiki/<cat>/page.md is served from docs/<cat>/page.md, so the image is one level closer.
      page_dir = File.join(DOCS, File.dirname(file_in_wiki).delete_prefix(KB::WIKI))
      image = File.join(DOCS, target.delete_prefix("#{KB::ROOT}/"))
      next "#{prefix}#{Pathname(image).relative_path_from(Pathname(page_dir))}"
    end

    "#{prefix}#{REPO_BLOB}/#{target.delete_prefix("#{KB::ROOT}/")}"
  end
end

def meta_line(header)
  canon = Array(header['canon']).map { CANON_NAMES.fetch(_1, _1) }.join(', ')
  sources = Array(header['sources']).size
  "<p class=\"wyd-meta\">Canon: <strong>#{canon}</strong> · #{sources} fonte#{'s' if sources != 1} · " \
    "atualizado em #{header['updated']}</p>\n\n"
end

FileUtils.rm_rf(OUT)
FileUtils.mkdir_p(File.join(DOCS, 'assets'))

Dir.glob(File.join(KB::WIKI, '**/*.md')).each do |src|
  rel = src.delete_prefix("#{KB::WIKI}/")
  text = relink(File.read(src), src)
  if File.basename(src) != 'README.md'
    header, body = KB.parse_page(src)
    body = relink(body, src).sub(/\A(\s*# .+\n)/) { "#{Regexp.last_match(1)}\n#{meta_line(header)}" }
    text = KB.render_page(header, body)
  end
  FileUtils.mkdir_p(File.dirname(File.join(DOCS, rel)))
  File.write(File.join(DOCS, rel), text)
end

Dir.glob(File.join(KB::ROOT, 'sources/*/data/images')).each do |dir|
  dest = File.join(DOCS, dir.delete_prefix("#{KB::ROOT}/"))
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp_r(dir, dest)
end

File.write(File.join(DOCS, 'tags.md'), "# Tags\n\nTodas as páginas agrupadas por tag.\n\n<!-- material/tags -->\n")
FileUtils.cp(File.join(KB::ROOT, 'site/extra.css'), File.join(DOCS, 'assets/extra.css'))

pages = KB.pages.group_by { |path, _h, _b| path.split('/').first }
nav = [{ 'Início' => 'README.md' }]
KB.categories.each do |key, cat|
  list = (pages[key] || []).sort_by { |_p, h, _b| h['title'].downcase.unicode_normalize(:nfkd) }
  nav << { cat['name'] => ["#{key}/README.md"] + list.map { |path, h, _b| { h['title'] => path } } }
end
nav << { 'Tags' => 'tags.md' }

config = YAML.load_file(File.join(KB::ROOT, 'site/mkdocs.yml'))
config['docs_dir'] = 'docs'
config['nav'] = nav
File.write(File.join(OUT, 'mkdocs.yml'), config.to_yaml(line_width: -1))
puts "Assembled #{KB.pages.size} pages in #{OUT}"

mode = (ARGV & %w[--build --serve]).first
exec('mkdocs', 'build', '--strict', '-f', File.join(OUT, 'mkdocs.yml'), '-d', File.join(OUT, 'html')) if mode == '--build'
exec('mkdocs', 'serve', '-f', File.join(OUT, 'mkdocs.yml')) if mode == '--serve'
