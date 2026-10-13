# frozen_string_literal: true

# Shared helpers for the knowledge base scripts in scripts/kb/.

require 'yaml'
require 'date'
require 'fileutils'

Encoding.default_external = Encoding::UTF_8

module KB
  # WYD_LORE_ROOT lets tests point the scripts at a scratch copy of the repo.
  ROOT = ENV.fetch('WYD_LORE_ROOT', File.expand_path('../..', __dir__))
  DIR = __dir__
  WIKI = File.join(ROOT, 'wiki')

  # Fields every page header must carry, in the order they are written.
  HEADER_FIELDS = %w[title summary category tags canon language sources updated].freeze

  module_function

  def categories = YAML.load_file(File.join(DIR, 'categories.yml'))
  def canon_labels = YAML.load_file(File.join(DIR, 'canon.yml'))

  # Splits a page into its YAML header (a Hash) and Markdown body.
  def parse_page(path)
    text = File.read(path)
    match = text.match(/\A---\n(.*?)\n---\n(.*)\z/m)
    raise "#{path}: missing YAML header" unless match

    [YAML.safe_load(match[1], permitted_classes: [Date]), match[2]]
  end

  def render_page(header, body)
    ordered = HEADER_FIELDS.to_h { [_1, header[_1]] }.compact.merge(header.except(*HEADER_FIELDS))
    "#{ordered.to_yaml(line_width: -1)}---\n\n#{body.strip}\n"
  end

  # Every content page, as [relative path under wiki/, header, body].
  def pages
    Dir.glob(File.join(WIKI, '*/*.md')).sort.reject { File.basename(_1) == 'README.md' }.map do |path|
      header, body = parse_page(path)
      [path.delete_prefix("#{WIKI}/"), header, body]
    end
  end
end
