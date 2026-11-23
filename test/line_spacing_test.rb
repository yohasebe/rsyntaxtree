# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"
require "rsvg2"

# The rows of a wrapped label are set as far apart as a connector stops short
# of the label (vmargin), where that is closer than the usual rhythm, and no
# closer than a quarter of the type.
class LineSpacingTest < Minitest::Test
  def generator(data, opts = {})
    RSyntaxTree::RSGenerator.new({ data: data, format: "svg" }.merge(opts))
  end

  # The baselines of the text in the drawing, top to bottom, of the label
  # whose first run is +first+.
  def baselines(svg, first)
    text = svg.split("<text ").find { |t| t.include?(">#{first}") }
    text.scan(/<tspan x='[-\d.e]+' y='([-\d.e]+)'/).flatten.map(&:to_f).uniq
  end

  def global(gen)
    gen.instance_variable_get(:@global)
  end

  def fontsize(gen)
    gen.instance_variable_get(:@params)[:fontsize]
  end

  def gap_between(svg, gen, first)
    a, b = baselines(svg, first)
    g = global(gen)
    b - a - g[:descender] - g[:cap_height]
  end

  def test_rows_close_up_to_the_connector_clearance
    gen = generator("[S [NP Gathered\\nin the yard]]", vmargin: 0.2)
    g = global(gen)

    assert_in_delta g[:single_x_metrics].height * 0.2, gap_between(gen.draw_svg, gen, "Gathered"), 0.01
  end

  def test_rows_are_never_set_wider_than_the_rhythm
    gen = generator("[S [NP Gathered\\nin the yard]]", vmargin: 0.4)
    a, b = baselines(gen.draw_svg, "Gathered")

    assert_in_delta global(gen)[:single_x_metrics].height, b - a, 0.01
  end

  def test_rows_stay_a_quarter_of_the_type_apart
    gen = generator("[S [NP Gathered\\nin the yard]]", vmargin: 0.1)

    assert_in_delta fontsize(gen) * RSyntaxTree::Element::LINE_GAP_FLOOR, gap_between(gen.draw_svg, gen, "Gathered"), 0.01
  end

  # Small type is measured at its own size, so a note in ___ closes up as
  # far as full-size text does.
  def test_small_rows_are_measured_at_their_own_size
    gen = generator("[S [V\\n___allows<>a___\\n___complement___ x]]", vmargin: 0.2)
    label = gen.send(:parsed_element_list).get_elements.find { |e| e.content.size == 3 }
    g = global(gen)
    small = SUBSCRIPT_CONST
    gap = g[:single_x_metrics].height * 0.2

    assert_in_delta g[:descender] + gap + g[:cap_height] * small, label.content[1][:advance], 0.01
    assert_in_delta (g[:descender] + g[:cap_height]) * small + gap, label.content[2][:advance], 0.01
  end

  # What is actually written is kept the floor apart even where it reaches
  # past the font's band — a box beside text, a raised superscript, an accent,
  # an emoji, an overline, a heavy stroke — measured on the drawing itself:
  # the rows of ink pixels the two lines leave, and the blank rows between.
  # Where the usual leading is already less than that, the rows stay at it,
  # no closer than they always were.
  def ink_row_gap(svg)
    handle = RSVG::Handle.new_from_data(svg)
    dim = handle.dimensions
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, dim.width, dim.height)
    Cairo::Context.new(surface).render_rsvg_handle(handle)
    stride = surface.stride
    data = surface.data
    inked = (0...dim.height).map do |y|
      (0...dim.width).any? { |x| data.getbyte((y * stride) + (x * 4) + 3) > 96 }
    end
    first = inked.index(true)
    last = inked.rindex(true)
    runs = inked[first..last].chunk(&:itself).map { |on, rows| [on, rows.size] }
    runs.reject(&:first).map(&:last).max || 0
  end

  [["[a|漢|\\na|漢|]"], ["[g\\n__A__]"], ["[x_g_\\nA]"], ["[😀\\n😀]"], ["[g\\nÁ]"],
   ["[g\\n____Á____]"], ["[g\\n__=x=__]"], ["[a*|g|*\\nA]", { linewidth: 3 }], ["[a--\\na--]"],
   ["[g\\n__=\\\\=__]"], ["[g\\n____|Á|____\\t___x___]"]].each do |data, extra|
    define_method "test_#{data}_keeps_its_rows_apart" do
      opts = { vmargin: 0.1, transparent: "on" }.merge(extra || {})
      gen = generator(data, opts)
      usual = generator(data, opts.merge(vmargin: 0.4))
      floor = fontsize(gen) * RSyntaxTree::Element::LINE_GAP_FLOOR

      assert_operator ink_row_gap(gen.draw_svg), :>=, [floor, ink_row_gap(usual.draw_svg)].min - 2
    end
  end

  # A bar is a stroke across the line, not a box: rows of them close up.
  def test_rows_of_bars_close_up
    tight = generator("[a--\\na--]", vmargin: 0.1).draw_svg[/height="([\d.]+)"/, 1].to_f
    usual = generator("[a--\\na--]", vmargin: 0.4).draw_svg[/height="([\d.]+)"/, 1].to_f

    assert_operator tight, :<, usual
  end

  # A grid of shapes closes up by its shapes, as it always has.
  def test_a_row_of_shapes_keeps_its_own_spacing
    data = "[|○|||\\n|×||○|]"
    tight = generator(data, vmargin: 0.1).draw_svg
    usual = generator(data, vmargin: 0.4).draw_svg

    assert_equal tight.scan(/<rect[^>]*y='([-\d.e]+)'/).flatten, usual.scan(/<rect[^>]*y='([-\d.e]+)'/).flatten
  end
end
