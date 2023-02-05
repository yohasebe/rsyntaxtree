#!/usr/bin/env ruby
# frozen_string_literal: true

examples_dir = File.expand_path(File.join(__dir__, "..", "docs", "_examples"))
svg_dir = File.expand_path(File.join(__dir__, "..", "docs", "assets", "svg"))
png_dir = File.expand_path(File.join(__dir__, "..", "docs", "assets", "img"))
Dir.glob("*.md", base: examples_dir).map do |md|
  md = File.join(examples_dir, md)
  config = YAML.load_file(md)
  rst = File.read(md).scan(/```([^`]+)```/m).last.first
  begin
    RSyntaxTree::RSGenerator.check_data(rst)
  rescue StandardError => e
    puts "Error detected in #{md}"
    pp e
    exit
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
    puts "Creating svg file: #{name}.svg"
    svg = rsg.draw_svg
    f.write(svg)
  end

  File.open(File.join(png_dir, "#{name}.png"), "w") do |f|
    puts "Creating png file: #{name}.png"
    png = rsg.draw_png
    f.write(png)
  end
end
