#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

directory = nil
directory = ARGV[0] if File.exist? ARGV[0]
doc_dir = File.expand_path(directory || File.join(__dir__, "..", "docs"))
examples_dir = File.join(doc_dir, "_examples")
svg_dir = File.join(doc_dir, "assets", "svg")
png_dir = File.join(doc_dir, "assets", "img")

logfile = File.open(File.join(doc_dir, "generate_examples.log"), "w")

Dir.glob("*.md", base: examples_dir).map do |md|
  md = File.join(examples_dir, md)
  config = YAML.load_file(md)
  rst = File.read(md).scan(/```([^`]+)```/m).last.first
  begin
    RSyntaxTree::RSGenerator.check_data(rst)
  rescue StandardError
    logfile.puts "Error detected in #{md}"
  end

  opts = {
    format: "png",
    leafstyle: "auto",
    fontstyle: "sans",
    fontsize: 16,
    linewidth: 1,
    margin: 1,
    vheight: 2.0,
    color: "modern",
    symmetrize: "on",
    transparent: "off",
    polyline: "off",
    hide_default_connectors: "off"
  }
  name = nil
  config.each do |key, value|
    next if value.to_s == ""

    case key
    when "name"
      name = value
      opts[:name] = name
    when "color"
      opts[:color] = case value
                     when "modern", "on", "true"
                       "modern"
                     when "traditional"
                       "traditional"
                     else
                       "off"
                     end
    when "linewidth", "line_width"
      opts[:linewidth] = value
    when "polyline"
      opts[:polyline] = value
    when "hide_default_connectors"
      opts[:hide_default_connectors] = value
    when "connector_height"
      opts[:vheight] = value
    when "symmetrization"
      opts[:symmetrize] = value
    when "connector"
      opts[:leafstyle] = value
    when "font"
      opts[:fontstyle] = case value
                         when /mono/i
                           "mono"
                         when /sans/i
                           "sans"
                         when /serif/i
                           "serif"
                         when /wqy/i
                           "cjk"
                         else
                           "sans"
                         end
    end
  end
  opts[:data] = rst
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
