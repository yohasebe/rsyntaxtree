# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "yaml"
require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class ExampleParserTest < Minitest::Test
  examples_dir = File.expand_path(File.join(__dir__, "..", "docs", "_examples"))
  svg_dir = File.expand_path(File.join(__dir__, "..", "docs", "assets", "svg"))

  Dir.glob("*.md", base: examples_dir).map do |md|
    md = File.join(examples_dir, md)
    config = YAML.load_file(md)
    rst = File.read(md).scan(/```([^`]+)```/m).last.first

    opts = {
      format: "png",
      leafstyle: "auto",
      fontstyle: "sans",
      fontsize: 16,
      linewidth: 1,
      margin: 1,
      vheight: 2.0,
      color: "on",
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
      when "color"
        opts[:color] = case value
                       when "modern", "on", "true"
                         "modern"
                       when "traditional"
                         "traditional"
                       else
                         "off"
                       end
      when "polyline"
        opts[:polyline] = value
      when "hide_default_connectors"
        opts[:hide_default_connectors] = value
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

    #################################
    # To test SVG, run the code below
    #################################
    svg = rsg.draw_svg
    opts[:svg] = svg
    svg_path = File.join(svg_dir, "#{name}.svg")
    svg_code = File.read(svg_path)
    puts "Creating example SVG test case: #{name}"

    define_method "test_#{name}" do
      assert_equal svg_code, opts[:svg]
    end
  end
end
