# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "nokogiri"
require "json"
require_relative "../lib/rsyntaxtree"

class NodeStylingTest < Minitest::Test
  def setup
    @base_opts = { fontstyle: "sans" }
  end

  # ===================
  # Colour schemes
  # ===================

  # The gray scheme exists for figures whose links outnumber their labels: the
  # text stays black and the lines that hold the diagram together go grey.
  def test_gray_scheme_draws_lines_grey_and_text_black
    opts = @base_opts.merge(data: "[S [NP hello] [VP world]]", color: "gray")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    lines = svg.scan(/<line style=[^>]*>/)
    refute_empty lines
    assert lines.all? { |l| l.include?("stroke:#666666") }, "connectors should be grey"
    assert svg.include?("fill: black"), "labels should stay black"
  end

  def test_gray_scheme_colours_movement_paths
    opts = @base_opts.merge(data: "[S [NP+1 hello] [VP [V+>1 world]]]", color: "gray")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    assert svg.include?("#666666"), "movement paths should be grey"
  end

  def test_grey_spelling_is_accepted
    a = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: "[S [NP a] [VP b]]", color: "gray")).draw_svg
    b = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: "[S [NP a] [VP b]]", color: "grey")).draw_svg

    assert_equal a, b
  end

  def test_other_schemes_keep_black_connectors
    %w[modern traditional off].each do |scheme|
      opts = @base_opts.merge(data: "[S [NP hello] [VP world]]", color: scheme)
      svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

      assert svg.scan(/<line style=[^>]*>/).all? { |l| l.include?("stroke:black") },
             "#{scheme} should leave connectors black"
    end
  end

# ===================
# Hyphens
# ===================

# Feature names in HPSG and its relatives are full of hyphens — HEAD-DTR,
# RELIED-ON — and by default each one has to be escaped, since a hyphen
# opens an underline. hyphen: literal trades the two readings.
def test_literal_hyphen_mode_writes_hyphens_plainly
  opts = @base_opts.merge(data: "[S [N RELIED-ON]]", hyphen: "literal")
  svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

  assert_includes Nokogiri::XML(svg).css("text").map(&:text).join, "RELIED-ON"
end

def test_markup_mode_still_rejects_a_lone_hyphen
  assert_raises(RSTError) do
    RSyntaxTree::RSGenerator.new(@base_opts.merge(data: "[S [N RELIED-ON]]")).draw_svg
  end
end

def test_literal_hyphen_mode_underlines_with_the_escape
  opts = @base_opts.merge(data: '[S [N \-under\-]]', hyphen: "literal")
  svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

  assert_includes svg, "underline"
end

def test_markup_mode_is_the_default
  plain = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: "[S [N -under-]]")).draw_svg
  assert_includes plain, "underline"
end

  # ===================
  # Nested matrices
  # ===================

  # A feature structure holds another feature structure as the value of an
  # attribute. Without that, HEAD and CASE have to be written as siblings,
  # which is not what the theory says.
  def test_nested_matrix_draws_its_own_brackets
    plain = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#HEAD\tnoun]')).draw_svg
    nested = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#HEAD\t#(noun\nCASE\tnom#)]')).draw_svg

    assert_operator nested.scan(/<polyline/).size, :>, plain.scan(/<polyline/).size,
                    "the nested matrix should add a pair of brackets"
    assert_includes nested, "CASE"
  end

  def test_nested_matrix_makes_the_label_taller
    flat = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#HEAD\tnoun]')).draw_svg
    nested = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#HEAD\t#(noun\nCASE\tnom#)]')).draw_svg

    assert_operator nested[/height="([\d.]+)"/, 1].to_f, :>, flat[/height="([\d.]+)"/, 1].to_f
  end

  def test_rows_after_a_nested_matrix_clear_it
    svg = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#HEAD\t#(a\nb\nc#)\nSPR\tx]')).draw_svg
    ys = Nokogiri::XML(svg).css("tspan").map { |s| [s.text, s["y"].to_f] }
    matrix_bottom = ys.select { |t, _| t == "c" }.map(&:last).max
    spr = ys.select { |t, _| t == "SPR" }.map(&:last).max

    refute_nil matrix_bottom
    refute_nil spr
    assert_operator spr, :>, matrix_bottom, "SPR should sit below the matrix it follows"
  end

  def test_matrices_nest_to_any_depth
    svg = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#A\t#(B\t#(C\t#(D\tvalue#)#)#)]')).draw_svg

    %w[A B C D value].each { |t| assert_includes svg, t }
  end

  # ===================
  # Column alignment (\t)
  # ===================

  # An attribute-value matrix is a two-column table: without alignment the
  # values start wherever the attribute name happens to end.
  def test_tabstop_aligns_values_across_lines
    data = '[#HEAD\tnoun\nSPR\tempty\nCOMPS\tlist]'
    svg = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: data)).draw_svg
    doc = Nokogiri::XML(svg)

    # All three rows live in one <text>; a value cell is the span that follows
    # the empty span the separator leaves behind.
    spans = doc.css("text").flat_map { |t| t.css("tspan").to_a }
    starts = spans.each_cons(2).filter_map do |separator, value|
      value["x"].to_f.round(1) if separator.text.strip.empty?
    end

    assert_equal 3, starts.size, "every row should have a value cell"
    assert_equal 1, starts.uniq.size, "values should start at one column: #{starts.inspect}"
  end

  def test_tabstop_widens_the_label_to_the_widest_cell
    narrow = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#A\tb]')).draw_svg
    wide = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: '[#A\tb\nAAAAAAAA\tb]')).draw_svg

    assert wide[/width="([\d.]+)"/, 1].to_f > narrow[/width="([\d.]+)"/, 1].to_f,
           "the widest attribute should set the column width"
  end

  def test_label_without_tabstop_is_unchanged
    before = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: "[S [NP hello] [VP world]]")).draw_svg
    assert_includes before, "hello"
    refute_includes before, "\t"
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

  def test_region_keeps_margin_from_canvas_edge
    # Regression: when a region's padded bounds extend past the tree's natural
    # extent (here an enclosed multi-line node deep in the shaded subtree), the
    # canvas must grow with a margin so the plane does not touch the image edge.
    opts = @base_opts.merge(color: "modern", data: "[S [A x] [%B [C #\\+one\\ \\+two]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    minx, miny, vbw, vbh = svg[/viewBox="([^"]*)"/, 1].split(",").map(&:to_f)
    shade = svg[/<rect[^>]*fill-opacity[^>]*>/]
    refute_nil shade
    rx = shade[/\bx='([\-0-9.]+)'/, 1].to_f
    ry = shade[/\by='([\-0-9.]+)'/, 1].to_f
    rw = shade[/width='([\-0-9.]+)'/, 1].to_f
    rh = shade[/height='([\-0-9.]+)'/, 1].to_f

    bottom_margin = (miny + vbh) - (ry + rh)
    right_margin = (minx + vbw) - (rx + rw)
    assert bottom_margin > 8, "Region must keep a bottom margin from the canvas edge (got #{bottom_margin.round(1)})"
    assert right_margin > 8, "Region must keep a right margin from the canvas edge (got #{right_margin.round(1)})"
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
  # ===================
  # Geometry invariants
  # ===================

  # Each of the three faults this batch shipped and took back was a pair of
  # things that stopped agreeing, and none of them broke a single element badly
  # enough for a test that looks at one thing at a time to notice.

  # A grid is drawn by putting nothing but shapes on a line. Consecutive rows
  # have to meet, or the grid shows a seam.
  def test_rows_of_shapes_only_meet
    opts = @base_opts.merge(data: '[|a||b|\n|c||d|]')
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    rows = svg.scan(/<rect style='stroke[^>]*y='([\-\d.]+)'[^>]*height='([\d.]+)'/m)
              .map { |y, h| [y.to_f, h.to_f] }.sort_by(&:first)
    assert_equal 4, rows.size, "four boxes in two rows of two"
    assert_in_delta rows[0][0] + rows[0][1], rows[2][0], 0.001,
                    "the second row should sit on the first, not below a gap"
  end

  # A level is placed by the height of the nodes above it, so a node whose
  # label is only a shape must not measure short of one holding plain text.
  def test_circled_and_plain_leaves_share_a_baseline
    opts = @base_opts.merge(data: "[S [{D} [a] [b]] [G [c] [d]]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    baselines = svg.scan(/<tspan[^>]*y='([\d.]+)'[^>]*>([^<]*)/)
                   .select { |_y, t| ["a", "b", "c", "d"].include?(t.strip) }
                   .map { |y, _t| y.to_f.round(3) }
    assert_equal 4, baselines.size
    assert_equal 1, baselines.uniq.size,
                 "leaves at one depth share a baseline, circled ancestor or not"
  end

# The enclosure is drawn on the node's own edge, so the node has to be laid
# out at the width the enclosure needs. Drawn any wider, it reaches past
# where the tree thinks the node ends, and everything attached to the node —
# connectors, movement arrows, the neighbour beside it — is left pointing at
# a boundary that is no longer there.
def test_an_enclosure_stays_inside_the_node_it_encloses
  opts = @base_opts.merge(data: "[S [##Alpha [b]] [##Beta [c]]]")
  generator = RSyntaxTree::RSGenerator.new(opts)
  svg = generator.draw_svg
  nodes = JSON.parse(RSyntaxTree::RSGenerator.new(opts).draw_json)["nodes"]

  boxed = nodes.select { |n| n.dig("style", "enclosure") == "rectangle" }
               .map { |n| [n["position"]["x"], n["position"]["x"] + n["position"]["content_width"]] }
               .sort_by(&:first)
  spans = svg.scan(/<polygon[^>]*points='([^']*)'/m).flatten.map do |points|
    xs = points.split(/\s+/).map { |p| p.split(",").first.to_f }
    [xs.min, xs.max]
  end.sort_by(&:first)

  assert_equal 2, boxed.size
  assert_equal 2, spans.size
  boxed.zip(spans).each do |node, drawn|
    assert drawn[0] >= node[0] - 0.001 && drawn[1] <= node[1] + 0.001,
           "the rectangle #{drawn.inspect} should stay inside the node #{node.inspect}"
  end
end

  # The declared size and the viewBox have to agree, or the whole figure is
  # scaled down and letterboxed inside its own canvas.
  def test_declared_size_matches_the_view_box
    opts = @base_opts.merge(data: "[S [NP a] [VP b]]")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg

    width = svg[/<svg width="([\d.]+)"/, 1].to_f
    height = svg[/<svg width="[\d.]+" height="([\d.]+)"/, 1].to_f
    box = svg[/viewBox="[\-\d.]+, [\-\d.]+, ([\d.]+), ([\d.]+)"/, 0]
    refute_nil box
    assert_in_delta ::Regexp.last_match(1).to_f, width, 0.001
    assert_in_delta ::Regexp.last_match(2).to_f, height, 0.001
  end

  # ===================
  # Line-type connections
  # ===================

  # A link between two boxes runs from just off one edge to just off the
  # other. It used to be anchored a full inter-node gap outside each box, so
  # a wide gap left the link floating short of both boxes and a narrow gap
  # pushed it into them.
  def link_geometry(data, opts_extra = {})
    opts = @base_opts.merge({ data: data }.merge(opts_extra))
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg
    doc = Nokogiri::XML(svg)

    # Enclosure boxes are the 4-cornered polygons; arrowheads are triangles.
    boxes = doc.css("polygon").select { |p| p["points"].split.size == 4 }.map do |p|
      xs = p["points"].split.map { |pt| pt.split(",").first.to_f }
      [xs.min, xs.max]
    end.sort_by(&:first)
    link = doc.css("line").find { |l| l["style"].to_s =~ /#CC79A7|#666666|purple/ }
    [boxes, link, doc]
  end

  def test_a_link_between_wide_spaced_boxes_reaches_both
    # Two boxed nodes far apart, mirroring the Schema network figure (036):
    # the link must close most of the gap, not float in the middle of it.
    # The old anchor sat a full inter-node gap off each box; with hspacing
    # pushed up that is ~16px a side, while the new margin is a quarter of it.
    boxes, link, = link_geometry("[S [##Prototype+-1] [##Extention+-1]]", hspacing: 2.0)
    refute_nil link, "no link drawn"

    left, right = boxes
    x1 = link["x1"].to_f
    x2 = link["x2"].to_f
    assert_operator x1, :>=, left[1], "link starts inside the left box"
    assert_operator x2, :<=, right[0], "link ends inside the right box"
    assert_operator x1 - left[1], :<=, 8, "link falls too short of the left box"
    assert_operator right[0] - x2, :<=, 8, "link falls too short of the right box"
  end

  def test_a_link_between_narrow_spaced_boxes_stays_out_of_them
    # The quicksort figure (043) packs its bottom leaves a few pixels apart:
    # with the old fixed offset the link between them shrank to a stub a few
    # pixels long in a 34px gap. Drawn from the gallery example itself so the
    # test tracks the layout that actually broke.
    require_relative "../dev/example_options"
    _name, opts = ExampleOptions.load(File.expand_path("../docs/_examples/043.md", __dir__))
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)

    # Boxes come in two forms: |x| decorations are <rect> (circles carry rx,
    # so exclude those), ## enclosures are 4-cornered <polygon>s.
    rects = doc.css("rect").reject { |r| r.key?("rx") || r["fill"] == "white" }.map do |r|
      x = r["x"].to_f
      y = r["y"].to_f
      [x, x + r["width"].to_f, y, y + r["height"].to_f]
    end
    polys = doc.css("polygon").select { |p| p["points"].split.size == 4 }.map do |p|
      xs = p["points"].split.map { |pt| pt.split(",").first.to_f }
      ys = p["points"].split.map { |pt| pt.split(",").last.to_f }
      [xs.min, xs.max, ys.min, ys.max]
    end
    boxes = rects + polys
    bottom_y = boxes.map { |b| b[3] }.max
    bottom = boxes.select { |b| (b[3] - bottom_y).abs < 2 }.sort_by(&:first)
    links = doc.css("line").select { |l| l["style"].to_s =~ /#CC79A7|purple/ }
    bottom_links = links.select { |l| (l["y1"].to_f - bottom_y).abs < 40 }
    assert_operator bottom_links.size, :>=, 2, "the bottom row should carry links"

    bottom_links.each do |link|
      left = bottom.select { |b| b[1] <= link["x1"].to_f + 0.001 }.max_by { |b| b[1] }
      right = bottom.select { |b| b[0] >= link["x2"].to_f - 0.001 }.min_by { |b| b[0] }
      refute_nil left, "link starts inside a box"
      refute_nil right, "link ends inside a box"
      gap = right[0] - left[1]
      assert_operator link["x2"].to_f - link["x1"].to_f, :>=, gap * 0.5,
                      "link covers too little of the gap between #{left.inspect} and #{right.inspect}"
    end
  end

  def test_bothways_arrowheads_stay_between_the_boxes
    # The bothways arrow is drawn at the midpoint of the link. The fixed-size
    # marker it used to be was wider than a narrow gap, spilling over both
    # boxes; the arrowheads are now sized to the link itself.
    boxes, link, doc = link_geometry("[S [NP [A [##1+->1] [##2+-<1]]] [VP x]]", tidy: "high")
    refute_nil link, "no link drawn"

    left, right = boxes
    heads = doc.css("polygon").select { |p| p["style"].include?("fill:#CC79A7") || p["style"].include?("fill: #CC79A7") }
    assert_equal 2, heads.size, "a bothways link should draw two arrowheads"
    heads.each do |h|
      xs = h["points"].split.map { |pt| pt.split(",").first.to_f }
      assert_operator xs.min, :>=, left[1], "arrowhead reaches into the left box"
      assert_operator xs.max, :<=, right[0], "arrowhead reaches into the right box"
    end
  end

  def test_an_ltr_link_between_siblings_is_vertical_and_clear
    # In LTR, siblings stack vertically. The link used to be anchored with
    # the movement-path offsets, coming out diagonal and floating off both
    # boxes; it should be vertical and run between the facing edges.
    opts = @base_opts.merge(data: "[S [NP [Det the] [N cat+-1]] [VP [V chased+-1] [NP mice]]]", direction: "ltr")
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg
    doc = Nokogiri::XML(svg)

    link = doc.css("line").find { |l| l["style"] =~ /#CC79A7|purple/ }
    refute_nil link, "no link drawn"
    assert_in_delta link["x1"].to_f, link["x2"].to_f, 0.001, "the link should be vertical"
    assert_operator (link["y2"].to_f - link["y1"].to_f).abs, :>, 0, "the link has no length"
  end

  # ===================
  # Room for the arrow
  # ===================

  # A full-size bothways arrow spans three inter-node gaps; the layout
  # spreads a linked pair until the gap between their boxes holds it
  # (4.25 gaps: 3 / 0.8 for the span plus the link's end margins). The
  # unlinked pair beside it calibrates the gap unit: four of them in the
  # default layout.
  def test_linked_siblings_get_room_for_a_full_size_arrow
    opts = @base_opts.merge(data: "[S [A [##1+-1] [##2+-1] [##3] [##4]]]")
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)
    boxes = doc.css("polygon").select { |p| p["points"].split.size == 4 }.map do |p|
      xs = p["points"].split.map { |pt| pt.split(",").first.to_f }
      [xs.min, xs.max]
    end.sort_by(&:first)
    assert_equal 4, boxes.size

    linked_gap = boxes[1][0] - boxes[0][1]
    unlinked_gap = boxes[3][0] - boxes[2][1]
    h_gap = unlinked_gap / 4.0
    assert_operator linked_gap, :>=, h_gap * 4.2,
                    "linked pair too close for a full-size arrow: #{linked_gap} vs #{h_gap * 4.25}"
  end

  def test_link_spreading_leaves_unlinked_pairs_alone
    opts = @base_opts.merge(data: "[S [A [##1+-1] [##2+-1] [##3] [##4]]]")
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)
    boxes = doc.css("polygon").select { |p| p["points"].split.size == 4 }.map do |p|
      xs = p["points"].split.map { |pt| pt.split(",").first.to_f }
      [xs.min, xs.max]
    end.sort_by(&:first)

    unlinked_gap = boxes[3][0] - boxes[2][1]
    linked_gap = boxes[1][0] - boxes[0][1]
    assert_in_delta unlinked_gap * (4.25 / 4.0), linked_gap, 1.0,
                    "only the linked pair should have been spread"
  end

  def test_043_bottom_pairs_hold_a_full_size_arrow
    # The bottom linked pairs of the quicksort figure sat one tidy_gap
    # (2.5 inter-node gaps) apart and the arrow shrank to fit. The unlinked
    # pairs on the same row calibrate the unit.
    require_relative "../dev/example_options"
    _name, opts = ExampleOptions.load(File.expand_path("../docs/_examples/043.md", __dir__))
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)

    boxes = doc.css("rect").reject { |r| r.key?("rx") || r["fill"] == "white" }.map do |r|
      x = r["x"].to_f
      y = r["y"].to_f
      [x, x + r["width"].to_f, y, y + r["height"].to_f]
    end
    bottom_y = boxes.map { |b| b[3] }.max
    bottom = boxes.select { |b| (b[3] - bottom_y).abs < 2 }.sort_by(&:first)
    gaps = bottom.each_cons(2).map { |a, b| [a, b, b[0] - a[1]] }
    tightest = gaps.map { |g| g[2] }.min
    h_gap = tightest / 2.5 # the unlinked pairs sit one tidy_gap apart
    linked = gaps.select { |_, _, g| g > tightest + 1 }
    refute_empty linked, "no spread pair found on the bottom row"
    linked.each do |_, _, g|
      assert_operator g, :>=, h_gap * 4.2, "linked pair too close for a full-size arrow"
    end

    heads = doc.css("polygon").select { |p| p["points"].split.size == 3 && p["style"].to_s.include?("fill:#CC79A7") }
    refute_empty heads
    spans = heads.map do |h|
      xs = h["points"].split.map { |pt| pt.split(",").first.to_f }
      [xs.min, xs.max]
    end.sort_by(&:first)
    spans.each_slice(2) do |left_head, right_head|
      assert_operator right_head[1] - left_head[0], :>=, h_gap * 3 * 0.9,
                      "bothways arrow smaller than full size"
    end
  end

  def test_link_spreading_keeps_every_tidy_mode_overlap_free
    data = "[S [A [##1+-1] [##2+-1] [##3] [##4]] [B [##5] [##6]]]"
    %w[off low medium high symmetric].each do |mode|
      opts = @base_opts.merge(data: data, tidy: mode)
      doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)
      boxes = doc.css("polygon").select { |p| p["points"].split.size == 4 }.map do |p|
        xs = p["points"].split.map { |pt| pt.split(",").first.to_f }
        ys = p["points"].split.map { |pt| pt.split(",").last.to_f }
        [xs.min, xs.max, ys.min, ys.max]
      end
      overlap = boxes.combination(2).any? do |a, b|
        a[0] < b[1] - 0.01 && b[0] < a[1] - 0.01 && a[2] < b[3] - 0.01 && b[2] < a[3] - 0.01
      end
      refute overlap, "tidy=#{mode}: boxes overlap after link spreading"
    end
  end

  # In a balanced tree the edge from an odd-child parent to its middle child
  # is vertical. The link spread pushes the right side of a pair rightward,
  # which can pull the parent's span centre off that middle child — the edge
  # comes out a few pixels off vertical. Assert the offset stays below a
  # pixel, for a plain balanced tree and for one whose wings are linked.
  def connector_dxs(doc)
    doc.css("line").filter_map do |l|
      next unless l["style"].to_s.include?("stroke:black")

      dx = (l["x1"].to_f - l["x2"].to_f).abs
      dy = (l["y1"].to_f - l["y2"].to_f).abs
      dx if dy > 30
    end
  end

  def test_middle_edge_stays_vertical_without_links
    opts = @base_opts.merge(data: "[S [A [B u] [C v] [D w]] [E x]]")
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)

    assert connector_dxs(doc).min < 1.0, "no vertical connector found at all"
    connector_dxs(doc).each do |dx|
      assert dx < 1.0 || dx > 10, "a slightly slanted connector: dx=#{dx.round(2)}"
    end
  end

  def test_middle_edge_stays_vertical_when_wings_are_linked
    # Three children, the outer two linked: spreading the pair must not
    # slant the parent's edge to the middle child.
    opts = @base_opts.merge(data: "[S [A [##1+-1] [##2] [##3+-1]] [B x]]")
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)

    connector_dxs(doc).each do |dx|
      assert dx < 1.0 || dx > 10, "a slightly slanted connector: dx=#{dx.round(2)}"
    end
  end

  # The quicksort figure is three nested three-way splits; its middle edges
  # measured vertical before the link spread and slanted after it.
  #
  # Asked as a gap, not as a count of pixels. This test used to require the
  # three smallest dx to be under 1.0 and the rest over 10, and those numbers
  # were read off one machine: the figure's width is decided by text
  # measurement, so the residual on a vertical edge is 0.45 here, 1.95 in the
  # container the gallery is drawn in, and the test passed nowhere but the
  # machine it was written on. What does not move between machines is the
  # distance between the two groups — a vertical edge is off by a fraction of a
  # pixel and a slanted one by tens — so that is what is asked about.
  def test_043_middle_edges_are_vertical
    require_relative "../dev/example_options"
    _name, opts = ExampleOptions.load(File.expand_path("../docs/_examples/043.md", __dir__))
    doc = Nokogiri::XML(RSyntaxTree::RSGenerator.new(opts).draw_svg)

    dxs = connector_dxs(doc).sort
    # The count is structure rather than metrics, so it holds everywhere, and
    # without it a figure that lost its edges could pass the ratio vacuously.
    assert_equal 17, dxs.size, "the quicksort figure has seventeen connectors"
    assert_operator dxs[3] / dxs[2], :>=, 10,
                    "the three middle edges are no longer set apart from the slanted ones: #{dxs.first(4).map { |d| d.round(2) }.inspect}"
  end

  # ===================
  # Hyphen readings
  # ===================

  # Two uses of the hyphen are structure, not markup: a line of them is the
  # horizontal rule, and the one in a path suffix makes that path dashed.
  # Trading the readings must leave both alone, and a label with no plain
  # hyphen in it must come out the same under either reading.
  def test_literal_hyphen_leaves_the_horizontal_rule_alone
    data = '[A x\n---\ny]'
    markup = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: data)).draw_svg
    literal = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: data, hyphen: "literal")).draw_svg

    refute_includes literal.scan(/<tspan[^>]*>([^<]*)/).flatten.map(&:strip), "---",
                    "the rule should be drawn, not printed"
    assert_equal markup, literal
  end

  def test_literal_hyphen_leaves_a_dashed_path_alone
    data = "[A [B x+-1] [C y+-1]]"
    markup = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: data)).draw_svg
    literal = RSyntaxTree::RSGenerator.new(@base_opts.merge(data: data, hyphen: "literal")).draw_svg

    assert_equal markup, literal
  end

  # A line-type connection takes two ends, like a path. One end used to walk
  # off the end of a pool that was never filled.
  def test_a_line_with_one_end_is_rejected
    opts = @base_opts.merge(data: "[A [B x+-2] [C y]]")
    error = assert_raises(RSTError) { RSyntaxTree::RSGenerator.new(opts).draw_svg }
    assert_match(/only one end/, error.message)
  end
  # ===================
  # TikZ export
  # ===================

  # The export cannot draw the brackets of a nested matrix, but it must not
  # drop what is inside them: a feature structure's entire contents used to
  # vanish from the TikZ output without a word.
  def test_tikz_keeps_the_contents_of_a_nested_matrix
    opts = @base_opts.merge(data: "[#PHON\tKim\nSYNSEM\t#(CASE\tnom#)]")
    tikz = RSyntaxTree::RSGenerator.new(opts).draw_tikz

    assert_includes tikz, "CASE"
    assert_includes tikz, "nom"
  end
end
