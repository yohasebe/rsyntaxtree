# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree"

class TikZTest < Minitest::Test
  def setup
    @simple_opts = {
      data: "[S [NP hello] [VP world]]",
      fontstyle: "sans"
    }
  end

  def test_draw_tikz_returns_string
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert_kind_of String, tikz
    refute_empty tikz
  end

  def test_tikz_contains_forest_environment
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("\\begin{forest}"), "Should contain forest begin"
    assert tikz.include?("\\end{forest}"), "Should contain forest end"
  end

  def test_tikz_contains_tree_structure
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("[S"), "Should contain root node S"
    assert tikz.include?("[NP"), "Should contain NP node"
    assert tikz.include?("[VP"), "Should contain VP node"
    assert tikz.include?("hello"), "Should contain terminal hello"
    assert tikz.include?("world"), "Should contain terminal world"
  end

  def test_tikz_with_nested_tree
    opts = {
      data: "[S [NP [Det the] [N dog]] [VP [V runs]]]",
      fontstyle: "sans"
    }
    rsg = RSyntaxTree::RSGenerator.new(opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("[Det"), "Should contain Det node"
    assert tikz.include?("[N"), "Should contain N node"
    assert tikz.include?("[V"), "Should contain V node"
    assert tikz.include?("the"), "Should contain terminal 'the'"
    assert tikz.include?("dog"), "Should contain terminal 'dog'"
  end

  def test_tikz_escapes_special_chars
    # Use % and $ which are LaTeX special but not RSyntaxTree special
    # (underscore _ is RSyntaxTree subscript markup, so we avoid it)
    opts = {
      data: "[S [NP 50%] [VP $100]]",
      fontstyle: "sans"
    }
    rsg = RSyntaxTree::RSGenerator.new(opts)
    tikz = rsg.draw_tikz

    # LaTeX special chars should be escaped
    assert tikz.include?("\\%"), "Should escape percent sign"
    assert tikz.include?("\\$"), "Should escape dollar sign"
  end

  def test_tikz_generates_standalone_option
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz(standalone: true)

    assert tikz.include?("\\documentclass"), "Standalone should have documentclass"
    assert tikz.include?("\\usepackage{forest}"), "Should include forest package"
    assert tikz.include?("\\begin{document}"), "Should have document begin"
    assert tikz.include?("\\end{document}"), "Should have document end"
  end

  def test_tikz_non_standalone_no_preamble
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz(standalone: false)

    refute tikz.include?("\\documentclass"), "Non-standalone should not have documentclass"
    refute tikz.include?("\\begin{document}"), "Non-standalone should not have document"
  end

  def test_tikz_region_shade
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%@yellow:NP a] [%VP b]]", fontstyle: "sans", color: "modern")
    tikz = rsg.draw_tikz

    yellow_rgb = "rgb,255:red,255;green,255;blue,0"
    assert tikz.include?("fit to=tree"), "Region node should fit a plane to its subtree"
    assert tikz.include?("on background layer"), "Region plane should sit behind the tree"
    assert tikz.include?("fill={#{yellow_rgb}}"), "Named shade color should resolve to rgb"
    assert tikz.include?("draw={#{yellow_rgb}}"), "Region plane should have a same-color border"
    assert tikz.include?("fill=gray"), "Bare '%' should use the default gray shade"
  end

  def test_tikz_region_explicit_color_honored_in_monochrome
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%@yellow:NP a] [%VP b]]", fontstyle: "sans", color: "off")
    tikz = rsg.draw_tikz

    assert tikz.include?("rgb,255:red,255;green,255;blue,0"), "Explicit shade color must be kept in color-off mode"
    assert tikz.include?("fill=gray"), "Bare '%' should still default to gray"
  end

  def test_tikz_region_hex_color
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%@#ffcc00:NP a] [VP b]]", fontstyle: "sans")
    tikz = rsg.draw_tikz

    assert tikz.include?("rgb,255:red,255;green,204;blue,0"),
           "Hex shade color should be converted to a TikZ rgb expression"
  end

  def test_tikz_region_short_hex_color
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%@#0a0:NP a] [VP b]]", fontstyle: "sans")
    tikz = rsg.draw_tikz

    assert tikz.include?("rgb,255:red,0;green,170;blue,0"),
           "3-digit hex should expand to a TikZ rgb expression"
  end

  def test_tikz_region_css_color_name
    # 'lightblue' is a valid SVG/CSS name but undefined in xcolor; it must be
    # resolved to an rgb expression so the generated LaTeX compiles.
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%@lightblue:NP a] [VP b]]", fontstyle: "sans")
    tikz = rsg.draw_tikz

    assert tikz.include?("rgb,255:red,173;green,216;blue,230"),
           "CSS color name should resolve to its rgb value (#add8e6)"
    refute tikz.include?("fill=lightblue"), "Should not emit a raw xcolor-undefined name"
  end

  def test_tikz_region_standalone_libraries
    rsg = RSyntaxTree::RSGenerator.new(data: "[S [%NP a] [VP b]]", fontstyle: "sans")
    with_region = rsg.draw_tikz(standalone: true)
    assert with_region.include?("\\usetikzlibrary{backgrounds,fit}"),
           "Standalone with a region should load backgrounds and fit libraries"

    plain = RSyntaxTree::RSGenerator.new(@simple_opts).draw_tikz(standalone: true)
    refute plain.include?("backgrounds,fit"),
           "Standalone without regions should not pull in extra libraries"
  end
end
