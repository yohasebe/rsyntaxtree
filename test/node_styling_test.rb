# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree"

class NodeStylingTest < Minitest::Test
  def setup
    @base_opts = { fontstyle: "sans" }
  end

  # ===================
  # Named color tests
  # ===================

  def test_named_color_red
    opts = @base_opts.merge(data: "[S [@red:NP hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red color styling"
    assert svg.include?("hello"), "Should contain the text"
  end

  def test_named_color_blue
    opts = @base_opts.merge(data: "[S [NP hello] [@blue:VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("blue"), "Should contain blue color styling"
  end

  def test_named_color_green
    opts = @base_opts.merge(data: "[S [@green:NP hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("green"), "Should contain green color"
  end

  # ===================
  # Hex color tests
  # ===================

  def test_hex_color_full
    opts = @base_opts.merge(data: "[S [@#FF0000:NP hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    # Hex color should be preserved in output
    assert svg.include?("#FF0000") || svg.include?("#ff0000"), "Should contain hex color"
  end

  def test_hex_color_short
    opts = @base_opts.merge(data: "[S [@#F00:NP hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    # Short hex should be converted or preserved
    assert svg.include?("#F00") || svg.include?("#f00") || svg.include?("#FF0000"), "Should contain hex color"
  end

  # ===================
  # Multiple colors in tree
  # ===================

  def test_multiple_colors
    opts = @base_opts.merge(data: "[S [@red:NP hello] [@blue:VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red"
    assert svg.include?("blue"), "Should contain blue"
  end

  def test_nested_colored_nodes
    opts = @base_opts.merge(data: "[S [@red:NP [@green:Det the] [N dog]] [VP runs]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red for NP"
    assert svg.include?("green"), "Should contain green for Det"
  end

  # ===================
  # Color with other decorations
  # ===================

  def test_color_with_bold
    opts = @base_opts.merge(data: "[S [@red:**NP** hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red color"
    assert svg.include?("bold"), "Should contain bold styling"
  end

  def test_color_with_italic
    opts = @base_opts.merge(data: "[S [@blue:*NP* hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("blue"), "Should contain blue color"
  end

  # ===================
  # Edge cases
  # ===================

  def test_color_on_terminal
    opts = @base_opts.merge(data: "[S [NP @red:hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should color terminal node"
  end

  def test_mixed_colored_and_uncolored
    opts = @base_opts.merge(data: "[S [NP hello] [@orange:VP world] [PP there]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("orange"), "Should contain orange color"
    # Other nodes should use default colors
    assert svg.include?("hello"), "Should contain uncolored text"
  end

  def test_color_without_interference
    # Ensure @ in other contexts doesn't break parsing
    opts = @base_opts.merge(data: "[S [NP hello] [VP world]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    refute_empty svg
  end

  # ===================
  # Color with enclosure (#)
  # ===================

  def test_color_with_brackets_enclosure
    # Order: # (enclosure) then @color:
    opts = @base_opts.merge(data: '[S [#@red:NP hello] [VP world]]')
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red color"
    # Check for bracket polyline (enclosure)
    assert svg.include?("polyline"), "Should contain bracket enclosure"
  end

  def test_color_with_rectangle_enclosure
    opts = @base_opts.merge(data: '[S [##@blue:NP hello] [VP world]]')
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("blue"), "Should contain blue color"
    assert svg.include?("polygon"), "Should contain rectangle enclosure"
  end

  def test_hex_color_with_enclosure
    opts = @base_opts.merge(data: '[S [#@#FF5733:NP hello] [VP world]]')
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("#FF5733") || svg.include?("#ff5733"), "Should contain hex color"
    assert svg.include?("polyline"), "Should contain bracket enclosure"
  end

  # ===================
  # Color with triangle (^)
  # ===================

  def test_color_with_triangle
    opts = @base_opts.merge(data: "[S [^@red:NP the quick fox] [VP runs]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red color"
    assert svg.include?("polygon"), "Should contain triangle"
  end

  def test_hex_color_with_triangle
    opts = @base_opts.merge(data: "[S [^@#00FF00:NP the lazy dog] [VP sleeps]]")
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("#00FF00") || svg.include?("#00ff00"), "Should contain hex color"
    assert svg.include?("polygon"), "Should contain triangle"
  end

  # ===================
  # Color with both enclosure and triangle
  # ===================

  def test_color_with_triangle_and_enclosure
    # Order: ^ (triangle) then # (enclosure) then @color:
    opts = @base_opts.merge(data: '[S [^#@purple:NP the quick fox] [VP runs]]')
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("purple"), "Should contain purple color"
    # Should have both triangle and bracket
    assert svg.count("polygon") >= 1, "Should contain polygon (triangle)"
    assert svg.include?("polyline"), "Should contain bracket enclosure"
  end

  def test_complex_tree_with_mixed_styling
    # Complex example like 056.md
    data = '[S [#@red:NP [^@blue:N the quick brown fox]] [#@green:VP [V jumps] [PP [P over] [^@purple:NP the lazy dog]]]]'
    opts = @base_opts.merge(data: data)
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg

    assert_kind_of String, svg
    assert svg.include?("red"), "Should contain red for NP"
    assert svg.include?("blue"), "Should contain blue for N"
    assert svg.include?("green"), "Should contain green for VP"
    assert svg.include?("purple"), "Should contain purple for NP"
  end
end
