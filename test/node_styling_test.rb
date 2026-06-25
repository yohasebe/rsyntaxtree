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

  # ===================
  # Region shade tests
  # ===================

  def test_region_shade_colored
    opts = @base_opts.merge(color: "modern", data: "[S [%@yellow:NP the dog] [VP [V barks]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade, "Should emit a semi-transparent region rectangle"
    assert shade.include?("fill='yellow'"), "Region shade should use the given color"
    assert shade.include?("stroke='yellow'"), "Region shade should have a same-color border"
    assert shade.include?("stroke-opacity"), "Border should be drawn with its own opacity"
  end

  def test_region_shade_default_color
    opts = @base_opts.merge(color: "modern", data: "[S [%NP the dog] [VP [V barks]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade, "Bare '%' should still emit a region rectangle"
    assert shade.include?("fill='#888888'"), "Bare '%' should use the default gray shade"
  end

  def test_region_shade_explicit_color_honored_in_monochrome
    # An explicit shade color is honored even in color-off mode, consistent
    # with how the @color: node-text color behaves.
    opts = @base_opts.merge(color: "off", data: "[S [%@yellow:NP the dog] [VP barks]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade, "Region should still render in color-off mode (not ignored)"
    assert shade.include?("fill='yellow'"), "Explicit shade color must be kept in color-off mode"
    assert shade.include?("stroke='yellow'"), "Border should match the explicit color"
  end

  def test_region_shade_bare_defaults_gray_in_monochrome
    opts = @base_opts.merge(color: "off", data: "[S [%NP the dog] [VP barks]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade
    assert shade.include?("fill='#888888'"), "Bare '%' should default to gray"
  end

  def test_region_shade_behind_tree
    opts = @base_opts.merge(data: "[S [%@yellow:NP the dog] [VP barks]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade_pos = svg.index("fill-opacity")
    text_pos = svg.index("<text")
    refute_nil shade_pos
    refute_nil text_pos
    assert shade_pos < text_pos, "Region shade must be drawn before (behind) node text"
  end

  def test_escaped_percent_is_literal
    opts = @base_opts.merge(color: "modern", data: "[S [NP \\%foo] [VP b]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    assert_nil svg[/<rect[^>]*fill-opacity[^>]*>/], "Escaped \\% must not create a region"
    texts = svg.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten.join
    assert texts.include?("%foo"), "Escaped \\% should render a literal % (got #{texts})"
  end

  def test_region_on_root_not_clipped
    # A region on the topmost node must not extend above the canvas: the
    # viewBox/background should grow to include the whole shade.
    opts = @base_opts.merge(color: "modern", data: "[%@orange:S [NP a] [VP b]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    minx, miny, vbw, vbh = svg[/viewBox="([^"]*)"/, 1].split(",").map(&:to_f)
    rect = svg[/<rect[^>]*fill-opacity[^>]*>/]
    rx = rect[/\bx='([\-0-9.]+)'/, 1].to_f
    ry = rect[/\by='([\-0-9.]+)'/, 1].to_f
    rw = rect[/width='([\-0-9.]+)'/, 1].to_f
    rh = rect[/height='([\-0-9.]+)'/, 1].to_f

    eps = 0.01
    assert ry >= miny - eps, "region top #{ry} clipped above viewBox top #{miny}"
    assert rx >= minx - eps, "region left #{rx} clipped beyond viewBox left #{minx}"
    assert ry + rh <= miny + vbh + eps, "region bottom clipped below viewBox"
    assert rx + rw <= minx + vbw + eps, "region right clipped beyond viewBox"
  end

  def test_smart_apostrophe_in_label
    # A straight ASCII apostrophe (U+0027) in a label is rendered as a
    # typographic apostrophe (U+2019) for smarter typography (e.g. X-bar "T'").
    opts = @base_opts.merge(data: "[TP [T' [T a]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    label = svg[%r{<tspan[^>]*>T\S*</tspan>}]
    assert svg.include?("T’"), "Apostrophe should render as U+2019 (got #{label.inspect})"
    refute svg.include?("T'"), "Straight ASCII apostrophe should not remain in a label"
  end

  def test_region_shade_in_ltr_layout
    # subtree_bounds runs after the LTR axis swap, so a region must still
    # produce a valid, finite rectangle in left-to-right layout.
    opts = @base_opts.merge(color: "modern", direction: "ltr",
                            data: "[S [NP a] [%@yellow:VP [V b]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade, "Region shade should render in LTR layout"
    w = shade[/width='([\-0-9.]+)'/, 1].to_f
    h = shade[/height='([\-0-9.]+)'/, 1].to_f
    assert w > 0 && h > 0, "LTR region rect should have positive size (#{w}x#{h})"
  end

  def test_no_region_no_shade
    opts = @base_opts.merge(data: "[S [NP the dog] [VP barks]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    assert_nil svg[/<rect[^>]*fill-opacity[^>]*>/], "Tree without '%' should have no region shade"
  end
end
