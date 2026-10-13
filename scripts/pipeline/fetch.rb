# frozen_string_literal: true

# Collects new and changed articles from the sources in sources/registry.yml.
#
# For every source whose `fetch.enabled` is true, a driver lists the source's
# items (articles, posts, wiki pages, archived snapshots), downloads the ones
# that are new or whose content changed, and archives them the same way as the
# original scrapes:
#
#   sources/<id>/data/articles/<slug>.html             raw HTML
#   sources/<id>/data/articles/markdown/<slug>.md      Markdown conversion
#   sources/<id>/data/images/<slug>_img_<n>.<ext>      images (when fetch.images is true)
#   sources/<id>/index.yml                             what was fetched, when, and its hash
#
# It writes the list of new and changed items to build/pipeline/changes.yml,
# which the AI update step reads to decide which wiki pages to write or update.
# Nothing in wiki/ is touched here.
#
#   ruby scripts/pipeline/fetch.rb                       # every enabled source
#   ruby scripts/pipeline/fetch.rb --source raidhut_news --limit 5
#   ruby scripts/pipeline/fetch.rb --registry path/to/registry.yml

require 'digest'
require 'json'
require 'net/http'
require 'optparse'
require 'uri'
require 'nokogiri'
require 'reverse_markdown'
require_relative '../kb/lib'

module Pipeline
  USER_AGENT = 'wyd-lore-archiver/1.0 (+https://github.com/kammradt/wyd-lore; fan preservation project)'
  MAX_IMAGE_BYTES = 2 * 1024 * 1024
  Item = Struct.new(:url, :title, :published, :html, keyword_init: true)

  module_function

  def get(url, limit: 5)
    uri = URI(url)
    raise "too many redirects for #{url}" if limit.zero?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                   open_timeout: 15, read_timeout: 30) do |http|
      http.get(uri.request_uri, 'User-Agent' => USER_AGENT, 'Accept-Language' => 'pt-BR,pt;q=0.9,en;q=0.5')
    end
    case response
    when Net::HTTPRedirection then get(URI.join(url, response['location']).to_s, limit: limit - 1)
    when Net::HTTPSuccess then response.body.force_encoding(Encoding::UTF_8).scrub
    else raise "HTTP #{response.code} for #{url}"
    end
  end

  def polite_get(url)
    attempts = 0
    begin
      attempts += 1
      body = get(url)
      sleep(@delay || 1.0)
      body
    rescue StandardError => e
      raise if attempts >= 3

      warn "  retrying #{url}: #{e.message}"
      sleep(2**attempts)
      retry
    end
  end

  def slugify(text, fallback)
    slug = text.to_s.unicode_normalize(:nfkd).encode('ASCII', undef: :replace, replace: '')
               .downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')[0, 80]
    slug.empty? ? fallback : slug
  end

  def absolutize(html, base)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    { 'a' => 'href', 'img' => 'src' }.each do |tag, attr|
      doc.css("#{tag}[#{attr}]").each do |node|
        node[attr] = URI.join(base, node[attr].strip).to_s
      rescue URI::Error
        next
      end
    end
    doc.to_html
  end

  # Picks the main content of a page: the configured selector, else <article>,
  # else <main>, else the body without navigation, scripts and footers.
  def main_content(html, selector)
    doc = Nokogiri::HTML(html)
    doc.css('script, style, noscript, iframe, nav, header, footer, form').remove
    node = (selector && doc.at_css(selector)) || doc.at_css('article') || doc.at_css('main') || doc.at_css('body')
    node ? node.inner_html : html
  end

  def to_markdown(html)
    ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).gsub(/\n{3,}/, "\n\n").strip
  end
end

# Each driver turns a source's `fetch` config into a list of items.
module Drivers
  module_function

  # Any RSS or Atom feed: Blogger, WordPress, Joomla (Raid Hut news).
  def feed(config)
    xml = Nokogiri::XML(Pipeline.polite_get(config.fetch('url')))
    xml.remove_namespaces!
    entries = xml.css('item').to_a + xml.css('entry').to_a
    entries.map do |entry|
      link = entry.at_css('link')&.text.to_s.strip
      link = entry.css('link').find { _1['rel'].nil? || _1['rel'] == 'alternate' }&.[]('href').to_s if link.empty?
      content = entry.at_css('encoded, content, description, summary')&.text.to_s
      Pipeline::Item.new(url: link, title: entry.at_css('title')&.text.to_s.strip,
                         published: entry.at_css('pubDate, published, updated')&.text.to_s.strip,
                         html: config['full_page'] ? nil : content)
    end
  end

  # A listing page whose links point at articles, e.g. the Kersef FAQ categories.
  def listing(config)
    items = []
    (1..(config['pages'] || 1)).each do |page|
      url = page == 1 ? config.fetch('url') : config.fetch('url') + format(config.fetch('page_param', '?page=%d'), page)
      begin
        doc = Nokogiri::HTML(Pipeline.polite_get(url))
      rescue StandardError => e
        raise if page == 1

        warn "  stopped at listing page #{page}: #{e.message}"
        break
      end
      found = doc.css(config.fetch('link_selector', 'a')).filter_map do |a|
        href = a['href'].to_s
        next unless href.match?(Regexp.new(config.fetch('link_pattern', '.')))

        Pipeline::Item.new(url: URI.join(url, href).to_s, title: a.text.strip)
      end
      break if found.empty? || (found.map(&:url) - items.map(&:url)).empty?

      items.concat(found)
    end
    items.uniq(&:url)
  end

  # MediaWiki sites such as Fandom: every page in the main namespace.
  def mediawiki(config)
    api = config.fetch('api')
    query = URI.encode_www_form(action: 'query', list: 'allpages', apnamespace: 0, apfilterredir: 'nonredirects',
                                aplimit: 500, format: 'json')
    titles = JSON.parse(Pipeline.polite_get("#{api}?#{query}")).dig('query', 'allpages').map { _1['title'] }
    titles.map do |title|
      Pipeline::Item.new(url: "#{config.fetch('page_base')}#{URI.encode_www_form_component(title.tr(' ', '_'))}",
                         title: title, html: nil)
    end
  end

  # Wayback Machine snapshots of an old site, one item per distinct URL.
  def wayback(config)
    params = { url: config.fetch('url'), output: 'json', fl: 'timestamp,original', filter: ['statuscode:200', 'mimetype:text/html'],
               collapse: 'urlkey', limit: config.fetch('cdx_limit', 500) }
    query = URI.encode_www_form(params)
    rows = JSON.parse(Pipeline.polite_get("https://web.archive.org/cdx/search/cdx?#{query}"))
    rows.drop(1).filter_map do |timestamp, original|
      next if config['url_pattern'] && !original.match?(Regexp.new(config['url_pattern']))

      Pipeline::Item.new(url: "https://web.archive.org/web/#{timestamp}id_/#{original}", title: original,
                         published: timestamp)
    end
  end

  # A fixed list of pages.
  def urls(config)
    config.fetch('urls').map { Pipeline::Item.new(url: _1, title: '') }
  end
end

options = { limit: nil, source: nil, registry: File.join(KB::ROOT, 'sources/registry.yml') }
OptionParser.new do |o|
  o.on('--source ID', 'Only fetch this source') { options[:source] = _1 }
  o.on('--limit N', Integer, 'At most N new or changed items per source') { options[:limit] = _1 }
  o.on('--registry PATH', 'Registry file') { options[:registry] = _1 }
  o.on('--delay SECONDS', Float, 'Pause between requests (default 1)') { Pipeline.instance_variable_set(:@delay, _1) }
end.parse!

registry = YAML.load_file(options[:registry])
sources = registry.fetch('sources').select { _1.dig('fetch', 'enabled') }
sources = sources.select { _1['id'] == options[:source] } if options[:source]
changes = []

sources.each do |source|
  id = source.fetch('id')
  config = source.fetch('fetch')
  dir = File.join(KB::ROOT, 'sources', id)
  index_path = File.join(dir, 'index.yml')
  index = File.exist?(index_path) ? YAML.load_file(index_path) : {}
  limit = options[:limit] || config.fetch('max_items_per_run', 50)
  # Sources the wiki already covers are archived silently on their first run,
  # so only later changes reach the AI update step.
  baseline = config['baseline_first_run'] && !File.exist?(index_path)
  limit = Float::INFINITY if baseline
  puts "== #{id} (#{config['driver']})#{' [baseline: archive only]' if baseline}"

  begin
    items = Drivers.public_send(config.fetch('driver'), config)
  rescue StandardError => e
    warn "  listing failed: #{e.message}"
    next
  end
  puts "  #{items.size} items listed"

  done = 0
  items.each do |item|
    break if done >= limit
    next if item.url.to_s.empty?

    begin
      raw = item.html || Pipeline.polite_get(item.url)
    rescue StandardError => e
      warn "  skipped #{item.url}: #{e.message}"
      next
    end
    content = Pipeline.absolutize(item.html ? raw : Pipeline.main_content(raw, config['content_selector']), item.url)
    markdown = Pipeline.to_markdown(content)
    next if markdown.length < config.fetch('min_chars', 200)

    digest = Digest::SHA256.hexdigest(markdown)
    known = index[item.url]
    next if known && known['sha256'] == digest

    slug = known&.dig('slug') || Pipeline.slugify(item.title.to_s.empty? ? URI(item.url).path : item.title, "item-#{index.size + 1}")
    slug = "#{slug}-#{index.size + 1}" if !known && index.values.any? { _1['slug'] == slug }
    FileUtils.mkdir_p(File.join(dir, 'data/articles/markdown'))
    File.write(File.join(dir, "data/articles/#{slug}.html"), raw)

    if config['images']
      FileUtils.mkdir_p(File.join(dir, 'data/images'))
      Nokogiri::HTML::DocumentFragment.parse(content).css('img[src]').each_with_index do |img, n|
        ext = File.extname(URI(img['src']).path).downcase
        ext = '.jpg' unless %w[.png .jpg .jpeg .gif .webp].include?(ext)
        name = "#{slug}_img_#{n}#{ext}"
        data = Pipeline.polite_get(img['src'])
        next if data.bytesize > Pipeline::MAX_IMAGE_BYTES

        File.binwrite(File.join(dir, 'data/images', name), data)
        markdown = markdown.gsub("(#{img['src']}", "(../../images/#{name}")
      rescue StandardError => e
        warn "  image skipped #{img['src']}: #{e.message}"
      end
    end

    archive = "sources/#{id}/data/articles/markdown/#{slug}.md"
    header = "<!-- source: #{item.url} | fetched: #{Date.today.iso8601} | registry id: #{id} -->\n\n"
    title_line = markdown.start_with?('# ') ? '' : "# #{item.title}\n\n"
    File.write(File.join(KB::ROOT, archive), "#{header}#{title_line}#{markdown}\n")
    index[item.url] = { 'slug' => slug, 'title' => item.title, 'published' => item.published,
                        'sha256' => digest, 'first_seen' => known&.dig('first_seen') || Date.today.iso8601,
                        'last_changed' => Date.today.iso8601 }.compact
    changes << { 'source' => id, 'canon' => source['canon'], 'status' => known ? 'changed' : 'new',
                 'url' => item.url, 'title' => item.title, 'archive' => archive } unless baseline
    done += 1
    puts "  #{known ? 'changed' : 'new'}: #{item.title} -> #{archive}"
  end

  FileUtils.mkdir_p(dir)
  File.write(index_path, index.sort.to_h.to_yaml(line_width: -1))
end

out = File.join(KB::ROOT, 'build/pipeline')
FileUtils.mkdir_p(out)
File.write(File.join(out, 'changes.yml'), changes.to_yaml(line_width: -1))
puts "#{changes.size} new or changed item(s); see build/pipeline/changes.yml"
