#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/rsyntaxtree"
require_relative "doc_figures"

# Draws the figure that stands beside each drawing example in the manual.
# Run in the container by `rake docker_generate`, alongside the gallery, so a
# manual figure is reproduced the same way a gallery one is.

doc_dir = File.expand_path(ARGV[0] || File.join(__dir__, "..", "docs"))
out_dir = File.join(doc_dir, "assets", DocFigures::DIRECTORY)
Dir.mkdir(out_dir) unless Dir.exist?(out_dir)

wanted = DocFigures.all(doc_dir).to_h { |code, asked| [DocFigures.name(code), [code, asked]] }

wanted.each do |name, (code, asked)|
  svg = RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(DocFigures.options(code, asked))).draw_svg
  File.write(File.join(out_dir, "#{name}.svg"), svg)
  puts "Creating doc figure: #{name}.svg"
rescue StandardError => e
  warn "#{name}: #{e.message}"
end

# A figure whose code has been edited away is no longer anyone's, and leaving it
# would make the directory grow a little with every wording change.
Dir.glob("doc-*.svg", base: out_dir).each do |file|
  next if wanted.key?(File.basename(file, ".svg"))

  File.delete(File.join(out_dir, file))
  puts "Removing figure for code no longer in the manual: #{file}"
end
