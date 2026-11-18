# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# corner_label sets a short string in a corner of the image, in a strip of
# its own beside the tree.
class CornerLabelTest < Minitest::Test
  TREE = "[S [NP the cat] [VP [V sat] [PP on the mat]]]"
  POSITIONS = %w[top-left top-right bottom-left bottom-right].freeze

  def generator(extra = {})
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(format: "svg", data: TREE).merge(extra))
  end

  # The figure, the tree's elements as drawn, and the corner label's settings.
  def drawn(extra = {})
    gen = generator(extra)
    params = gen.instance_variable_get(:@params)
    list = gen.send(:parsed_element_list)
    svg = RSyntaxTree::SVGGraph.new(list, params, gen.instance_variable_get(:@global)).svg_data
    [svg, list.get_elements, params[:corner]]
  end

  def view_box(svg)
    svg[/viewBox="([^"]+)"/, 1].split(",").map(&:to_f)
  end

  # Where the label is, from its text element and the font that sets it.
  def label_box(svg, corner)
    tag = svg[/<text x='[^']*' y='[^']*' white-space='pre' style='fill: #{Regexp.escape(corner[:color])};[^>]*>/]
    x = tag[/x='([-\d.]+)'/, 1].to_f
    baseline = tag[/y='([-\d.]+)'/, 1].to_f
    m = FontMetrics.get_metrics(corner[:text], FontFamily.for_pango(corner[:font_style]),
                                corner[:size] * FONT_SCALING, :normal, :normal)
    top = baseline - m.ink_above
    { left: x + m.ink_left, right: x + m.ink_left + m.ink_width, top: top, bottom: top + m.ink_height,
      strip: [m.width, m.ink_left + m.ink_width].max - [0, m.ink_left].min }
  end

  %w[ttb ltr btt].each do |direction|
    POSITIONS.each do |position|
      define_method "test_#{position}_stands_clear_of_the_tree_#{direction}" do
        svg, elements, corner = drawn(corner_label: "?*", corner_label_color: "red",
                                      corner_label_position: position, direction: direction)
        box = label_box(svg, corner)
        tree_left = elements.map(&:horizontal_indent).min
        tree_right = elements.map { |e| e.horizontal_indent + e.content_width }.max
        inked = elements.select(&:ink_top)

        if position.end_with?("left")
          assert_operator box[:right], :<, tree_left
        else
          assert_operator box[:left], :>, tree_right
        end
        if position.start_with?("top")
          assert_in_delta inked.map(&:ink_top).min, box[:top], 0.01
        else
          assert_in_delta inked.map(&:ink_bottom).max, box[:bottom], 0.01
        end

        vx, vy, vw, vh = view_box(svg)
        assert_operator box[:left], :>=, vx
        assert_operator box[:right], :<=, vx + vw
        assert_operator box[:top], :>=, vy
        assert_operator box[:bottom], :<=, vy + vh
      end
    end
  end

  def test_the_canvas_grows_by_the_label_and_one_gap
    plain = view_box(generator.draw_svg)
    svg, _, corner = drawn(corner_label: "*")
    box = label_box(svg, corner)
    gap = generator.instance_variable_get(:@global)[:h_gap_between_nodes]

    assert_in_delta plain[2] + box[:strip] + gap, view_box(svg)[2], 0.01
    assert_in_delta plain[3], view_box(svg)[3], 0.01
  end

  # A label taller than the whole tree still fits on the canvas.
  def test_a_label_taller_than_the_tree_fits
    svg, _, corner = drawn(data: "[S a]", fontsize: 6, corner_label: "*?", corner_label_size: 52,
                           corner_label_position: "bottom-right")
    box = label_box(svg, corner)
    _, vy, _, vh = view_box(svg)

    assert_operator box[:top], :>=, vy
    assert_operator box[:bottom], :<=, vy + vh
  end

  # A glyph whose ink starts left of its origin, large against a small tree
  # with tight margins, stays on the canvas.
  %w[bottom-left top-right].each do |position|
    define_method "test_an_overhanging_glyph_is_not_cut_off_#{position}" do
      svg, _, corner = drawn(data: "[S a]", fontsize: 6, hspacing: 0.5, corner_label: "ȉj",
                             corner_label_size: 52, corner_label_fontstyle: "serif",
                             corner_label_position: position)
      box = label_box(svg, corner)
      vx, _, vw, = view_box(svg)

      assert_operator box[:left], :>=, vx
      assert_operator box[:right], :<=, vx + vw
    end
  end

  def test_the_label_is_written_as_given
    svg = generator(corner_label: "*a* #b <&>").draw_svg

    assert_includes svg, ">*a* #b &lt;&amp;&gt;</text>"
  end

  def test_the_label_is_not_sheared
    svg = generator(corner_label: "*", shear: 20).draw_svg

    assert_operator svg.index("</g>"), :<, svg.index(">*</text>")
  end

  def test_defaults
    gen = generator(corner_label: "*", fontsize: 14, fontstyle: "serif")
    corner = gen.instance_variable_get(:@params)[:corner]

    assert_equal({ text: "*", position: "top-left", size: 21.0, color: "black", font_style: "serif" }, corner)
  end

  def test_no_label_when_none_is_given
    plain = generator.draw_svg

    assert_equal plain, generator(corner_label: "", corner_label_color: "").draw_svg
    assert_equal plain, generator(corner_label: nil, corner_label_position: "bottom-right").draw_svg
  end

  # The settings the drawing reads are the library's own, never a caller's.
  def test_a_callers_corner_key_is_not_drawn
    assert_equal generator.draw_svg, generator(corner: "").draw_svg
  end

  def test_raster_formats_draw_it
    gen = generator(corner_label: "✓", corner_label_color: "green")

    assert gen.draw_png.b.start_with?("\x89PNG".b)
    assert gen.draw_pdf.b.start_with?("%PDF".b)
  end

  def test_json_records_the_label
    params = JSON.parse(generator(corner_label: "#", corner_label_color: "#c00", corner_label_size: 20,
                                  corner_label_position: "top-right", corner_label_fontstyle: "mono")
                          .draw_json)["meta"]["source"]["params"]

    assert_equal({ "text" => "#", "position" => "top-right", "size" => 20.0,
                   "color" => "#c00", "font_style" => "mono" }, params["corner_label"])
    refute JSON.parse(generator.draw_json)["meta"]["source"]["params"].key?("corner_label")
  end

  {
    "top-left" => ["north east", "north west", "-0.5em"],
    "top-right" => ["north west", "north east", "0.5em"],
    "bottom-left" => ["south east", "south west", "-0.5em"],
    "bottom-right" => ["south west", "south east", "0.5em"]
  }.each do |position, (anchor, at, shift)|
    define_method "test_tikz_sets_the_label_#{position}" do
      tikz = generator(corner_label: "#", corner_label_position: position).draw_tikz

      assert_includes tikz, "anchor=#{anchor}, inner sep=0pt, scale=1.5,"
      assert_includes tikz, "at ([xshift=#{shift}]current bounding box.#{at}) {\\#};"
    end
  end

  def test_tikz_escapes_the_label
    tikz = generator(corner_label: "A&B\\c%").draw_tikz

    assert_includes tikz, "{A\\&B\\textbackslash{}c\\%};"
  end

  def test_tikz_without_a_label_is_unchanged
    refute_includes generator.draw_tikz, "current bounding box"
  end

  {
    corner_label_position: "middle",
    corner_label_color: "nocolour",
    corner_label_size: 99,
    corner_label_fontstyle: "fraktur",
    corner_label: "A\fB"
  }.each do |key, value|
    define_method "test_rejects_#{key}_#{value.to_s.dump}" do
      error = assert_raises(RSTError) { generator(corner_label: "*", key => value) }

      assert_equal :invalid_option, error.code
      assert_equal key.to_s, error.label
    end
  end
end
