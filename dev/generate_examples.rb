#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'
require_relative 'example_options'

directory = nil
directory = ARGV[0] if File.exist? ARGV[0]
doc_dir = File.expand_path(directory || File.join(__dir__, "..", "docs"))
examples_dir = File.join(doc_dir, "_examples")
svg_dir = File.join(doc_dir, "assets", "svg")
png_dir = File.join(doc_dir, "assets", "img")

logfile = File.open(File.join(doc_dir, "generate_examples.log"), "w")

Dir.glob("*.md", base: examples_dir).map do |md|
  md = File.join(examples_dir, md)
  name, opts = ExampleOptions.load(md)
  rst = opts[:data]
  begin
    RSyntaxTree::RSGenerator.check_data(rst, opts)
  rescue StandardError
    logfile.puts "Error detected in #{md}"
  end

  rsg = RSyntaxTree::RSGenerator.new(opts)

  File.open(File.join(svg_dir, "#{name}.svg"), "w") do |f|
    logfile.puts "Creating svg file: #{name}.svg"
    svg = rsg.draw_svg
    f.write(svg)
  rescue StandardError => e
    logfile.puts "Processing #{name}.svg"
    logfile.puts e.message
  end

  File.open(File.join(png_dir, "#{name}.png"), "w") do |f|
    logfile.puts "Creating png file: #{name}.png"
    png = rsg.draw_png
    f.write(png)
  rescue StandardError => e
    logfile.puts "Processing #{name}.png"
    logfile.puts e.message
  end
end

logfile.close
