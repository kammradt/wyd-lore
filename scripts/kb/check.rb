# frozen_string_literal: true

# Validates the knowledge base: page headers, categories, canon labels and
# relative links (pages and images). Exits non-zero when anything is wrong, so
# CI and the update pipeline can refuse a broken change.
#
#   ruby scripts/kb/check.rb

require_relative 'lib'

errors = []
categories = KB.categories.keys
canon = KB.canon_labels.keys

KB.pages.each do |path, h, body|
  where = "wiki/#{path}"
  folder = path.split('/').first
  missing = %w[title summary category tags canon language sources updated].reject { h[_1] && h[_1] != [] && h[_1] != '' }
  errors << "#{where}: missing header fields #{missing.join(', ')}" if missing.any?
  errors << "#{where}: unknown category folder #{folder}" unless categories.include?(folder)
  errors << "#{where}: category #{h['category']} does not match folder #{folder}" if h['category'] && h['category'] != folder
  bad_canon = Array(h['canon']) - canon
  errors << "#{where}: unknown canon #{bad_canon.join(', ')}" if bad_canon.any?
  errors << "#{where}: file name must be lowercase kebab-case" unless File.basename(path, '.md').match?(/\A[a-z0-9]+(-[a-z0-9]+)*\z/)
  Array(h['sources']).each do |s|
    errors << "#{where}: every source needs a name and a url" unless s.is_a?(Hash) && s['name'] && s['url']
    errors << "#{where}: archived copy #{s['archive']} not found" if s.is_a?(Hash) && s['archive'] && !File.exist?(File.join(KB::ROOT, s['archive']))
  end
  errors << "#{where}: body must start with the page title as H1" unless body.lstrip.start_with?("# #{h['title']}")
end

Dir.glob(File.join(KB::WIKI, '**/*.md')).each do |file|
  File.read(file).scan(/\]\(([^)\s]+)/).flatten.each do |link|
    next if link.match?(/\A(https?:|mailto:|#)/)

    target = File.expand_path(link.split('#').first, File.dirname(file))
    errors << "#{file.delete_prefix("#{KB::ROOT}/")}: broken link #{link}" unless File.exist?(target)
  end
end

if errors.empty?
  puts "OK: #{KB.pages.size} pages"
else
  puts errors
  abort "#{errors.size} problem(s) found"
end
