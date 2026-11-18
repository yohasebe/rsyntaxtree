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

  # An @ before a colour name and '(' opens a stretch wherever it stands;
  # \@ keeps it a character.
  def test_an_at_before_a_colour_and_a_parenthesis_opens_a_stretch
    assert_equal "red", colour_of("bob@red(comment)", "comment")
    assert_equal ["mail@example(x)"], runs("mail\\@example(x)").map { |r| r[:text] }
  end

  def test_parentheses_and_at_signs_elsewhere_are_text
    assert_equal ["a(b)"], runs('a\(b\)').map { |r| r[:text] }
    assert_equal ["f(x)"], runs('@red(f\(x\))').map { |r| r[:text] }
    assert_equal ["x@y.com (z)"], runs("x@y.com (z)").map { |r| r[:text] }
    assert_nil runs("@red:NP").first[:color], "the whole-label colour is the element's, not a run's"
  end

  def test_inside_a_matrix_cell
    svg = svg('[S [#(A\t@red(b)#) x]]')

    assert_match(/fill: red;[^>]*>b</, svg)
  end

  def test_svg_paints_text_and_shapes
    out = svg("[S [X {}->@red({/}<>|/|)->] [Y look @red(at) it]]")

    assert_match(/fill: red;[^>]*>at</, out)
    assert_equal 2, out.scan(/<rect style='stroke: red;/).size
    assert_equal 2, out.scan("fill='url(#hatchSpan0)'").size
    assert_match(/<pattern id="hatchSpan0"[^>]*><line [^>]*stroke="red"/, out)
  end

  def test_a_figure_without_a_hatched_stretch_has_no_extra_pattern
    refute_includes svg("[S [X @red(a) {/}]]"), "hatchSpan"
  end

  def test_the_colour_holds_with_colour_off
    assert_match(/fill: red;[^>]*>at</, svg("[S look @red(at) it]", color: "off"))
  end

  def test_json_segments_carry_the_colour
    data = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S look @red(at) it]", format: "json").draw_json)
    segments = data["nodes"].flat_map { |n| n["label"]["lines"].flat_map { |l| l["segments"] } }

    assert_equal "red", segments.find { |s| s["text"] == "at" }["color"]
    refute segments.find { |s| s["text"] == "look " }.key?("color")
  end

  # Text that only changes colour is one stretch: set as one, and written as
  # one where colour is dropped.
  def test_a_change_of_colour_does_not_split_the_text
    assert_match(/\[unhappiness\]/, RSyntaxTree::RSGenerator.new(data: "[S un@red(happi)ness]").draw_tikz)
    assert_includes svg("[S un@red(happi)ness]"), ">un<tspan style='fill: red;'>happi</tspan>ness</tspan>"
  end

  # Room for the parts set apart as well as together: a renderer may drop
  # the kerning at the change of colour.
  %w[AV To].each do |word|
    define_method "test_#{word}_has_room_for_its_parts_set_apart" do
      gen = RSyntaxTree::RSGenerator.new(data: "[S #{word[0]}@red(#{word[1]})]", format: "svg")
      params = gen.instance_variable_get(:@params)
      leaf = gen.send(:parsed_element_list).get_elements.last
      measure = ->(t) { FontMetrics.get_metrics(t, params[:fontset][:family], params[:fontsize], :normal, :normal).width }

      assert_equal [measure.call(word), measure.call(word[0]) + measure.call(word[1])].max, leaf.text_width
    end
  end

  def test_an_escaped_parenthesis_stays_in_the_stretch
    data = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S @red(a\\)b)]", format: "json").draw_json)

    assert_equal [{ "text" => "a)b", "decorations" => [], "color" => "red" }],
                 data["nodes"][1]["label"]["lines"].first["segments"]
  end

  def test_tikz_writes_the_text_once
    tikz = RSyntaxTree::RSGenerator.new(data: "[S look @red(at) it]").draw_tikz

    assert_match(/\[look\s+at\s+it\]/, tikz)
  end

  {
    "[S @nocolour(a)]" => :unknown_color,
    "[S @#12(a)]" => :invalid_color,
    "[S @red(a]" => :unclosed_markup,
    "[S **@red(a)**]" => :unclosed_markup,
    "[S @#3af(a]" => :unclosed_markup,
    "[S **@#3af(a)**]" => :unclosed_markup,
    "[S @wrong(@red(a))]" => :unknown_color,
    "[S @red()]" => :empty_markup
  }.each do |input, code|
    define_method "test_#{input}_is_refused_as_#{code}" do
      error = assert_raises(RSTError) { svg(input) }

      assert_equal code, error.code
    end
  end

  {
    "[S @#3af(a]" => "never closed with ')'",
    "[S @red(a]" => "never closed with ')'",
    "[S **@#3af(a)**]" => "inside other markup",
    "[S **@red(a)**]" => "inside other markup",
    "[S [A @red(x+1] [B y+>1]]" => "never closed with ')'",
    "[S @red()]" => "is empty",
    "[S a@red()b]" => "is empty",
    "[S @red(a\\tb)]" => "within its line or cell",
    "[S @red(a\\nb)]" => "within its line or cell",
    "[S @bleu(x)]" => "@blue(word)",
    "[S [A \\\\@red(x+1] [B y+>1]]" => "never closed with ')'",
    "[S @red(x\\ny]" => "within its line or cell",
    "[S @red(x\\ty]" => "within its line or cell"
  }.each do |input, hint|
    define_method "test_#{input}_is_told_#{hint}" do
      error = assert_raises(RSTError) { svg(input) }

      assert_includes error.hint, hint
    end
  end

  # A rule name is drawn as written; the escapes are the label's.
  def test_a_rule_name_shows_its_parentheses_as_written
    out = svg("[S\\tR\\(1\\) [N x] [V y]]", derivation: "on")

    assert_includes out, ">R(1)<"
    assert_includes svg("[S\\tR\\\\(1) [N x] [V y]]", derivation: "on"), ">R\\\\(1)<"
  end
end
