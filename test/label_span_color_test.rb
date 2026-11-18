# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/markup_parser"

# @color(...) colours part of a label: the runs inside it, and the shapes
# drawn around them.
class LabelSpanColorTest < Minitest::Test
  def runs(label)
    parsed = Markup.parse(label.gsub("<>", WHITESPACE_BLOCK))
    assert_equal :success, parsed[:status], label
    parsed[:results][:contents].flat_map { |line| line[:elements].to_a }
  end

  def colour_of(label, text)
    runs(label).find { |r| r[:text] == text }&.dig(:color)
  end

  def svg(data, extra = {})
    RSyntaxTree::RSGenerator.new({ data: data, format: "svg" }.merge(extra)).draw_svg
  end

  def test_the_runs_inside_take_the_colour
    assert_equal "red", colour_of("look @red(at) the chickens", "at")
    assert_nil colour_of("look @red(at) the chickens", "look ")
    assert_equal "#3af", colour_of("@#3af(x)", "x")
  end

  def test_an_inner_stretch_keeps_its_own_colour
    label = "@#c00(a @blue(b) c)"

    assert_equal "#c00", colour_of(label, "a ")
    assert_equal "blue", colour_of(label, "b")
    assert_equal "#c00", colour_of(label, " c")
  end

  def test_shapes_and_decorations_inside_take_the_colour
    rs = runs("{}->@red({/}<>|/|)->")
    coloured = rs.select { |r| r[:color] == "red" }.map { |r| r[:decoration] }

    assert_includes coloured, %i[hatched circle]
    assert_includes coloured, %i[hatched box]
    assert_nil rs.first[:color]
    assert_equal "red", runs("@red(**x**)").first[:color]
  end

  def test_a_line_break_ends_nothing_but_the_line
    assert_equal "gray", colour_of('NP\n@gray(causer)', "causer")
    assert_nil colour_of('NP\n@gray(causer)', "NP")
  end

  def test_parentheses_and_at_signs_elsewhere_are_text
    assert_equal ["a(b)"], runs('a\(b\)').map { |r| r[:text] }
    assert_equal ["f(x)"], runs('@red(f\(x\))').map { |r| r[:text] }
    assert_equal ["x@y.com (z)"], runs("x@y.com (z)").map { |r| r[:text] }
    assert_nil runs("@red:NP").first[:color], "the whole-label colour is the element's, not a run's"
  end

  def test_inside_a_matrix_cell
    svg = svg('[S [#(A\t@red(b)#) x]]')

    assert_match(/fill: red; [^>]*>b</, svg)
  end

  def test_svg_paints_text_and_shapes
    out = svg("[S [X {}->@red({/}<>|/|)->] [Y look @red(at) it]]")

    assert_match(/fill: red; [^>]*>at</, out)
    assert_equal 2, out.scan(/<rect style='stroke: red;/).size
    assert_equal 2, out.scan("fill='url(#hatchSpan0)'").size
    assert_match(/<pattern id="hatchSpan0"[^>]*><line [^>]*stroke="red"/, out)
  end

  def test_a_figure_without_a_hatched_stretch_has_no_extra_pattern
    refute_includes svg("[S [X @red(a) {/}]]"), "hatchSpan"
  end

  def test_the_colour_holds_with_colour_off
    assert_match(/fill: red; [^>]*>at</, svg("[S look @red(at) it]", color: "off"))
  end

  def test_json_segments_carry_the_colour
    data = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S look @red(at) it]", format: "json").draw_json)
    segments = data["nodes"].flat_map { |n| n["label"]["lines"].flat_map { |l| l["segments"] } }

    assert_equal "red", segments.find { |s| s["text"] == "at" }["color"]
    refute segments.find { |s| s["text"] == "look " }.key?("color")
  end

  def test_tikz_writes_the_text_once
    tikz = RSyntaxTree::RSGenerator.new(data: "[S look @red(at) it]").draw_tikz

    assert_match(/\[look\s+at\s+it\]/, tikz)
  end

  {
    "[S @nocolour(a)]" => :unknown_color,
    "[S @#12(a)]" => :invalid_color,
    "[S @red(a]" => :unclosed_markup,
    "[S **@red(a)**]" => :unclosed_markup
  }.each do |input, code|
    define_method "test_#{input}_is_refused_as_#{code}" do
      error = assert_raises(RSTError) { svg(input) }

      assert_equal code, error.code
    end
  end
end
