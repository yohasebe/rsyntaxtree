# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "open3"

require_relative "../lib/rsyntaxtree"

# Strokes follow the type size: linewidth 1 is 5% of it (the ratio of an
# ordinary text rule), each 0.5 step adds 2.5%, a bold stroke adds five
# percentage points. The option scale is 0.5-3.0. These tests fix the
# formula, the scale, and the spots that used to hold absolute values.
class StrokeWidthTest < Minitest::Test
  BIN_PATH = File.expand_path("../bin/rsyntaxtree", __dir__)

  def svg(opts = {})
    RSyntaxTree::RSGenerator.new({ data: "[S [NP a] [VP b]]", format: "svg" }.merge(opts)).draw_svg
  end

  def test_linewidth_1_is_five_percent_of_the_type_size
    # fontsize 16 -> internal 32; 5% is 1.6
    assert_includes svg, "stroke-width:1.6"
  end

  def test_strokes_scale_with_the_type_size
    assert_includes svg(fontsize: 8), "stroke-width:0.8"  # internal 16 * 5%
    assert_includes svg(fontsize: 26), "stroke-width:2.6" # internal 52 * 5%
  end

  def test_the_option_scale
    assert_includes svg(linewidth: 0.5), "stroke-width:0.8"  # 32 * 2.5%
    assert_includes svg(linewidth: 2.0), "stroke-width:3.2"  # 32 * 10%
    assert_includes svg(linewidth: 3.0), "stroke-width:4.8"  # 32 * 15%
  end

  def test_a_bold_stroke_adds_five_percentage_points
    out = RSyntaxTree::RSGenerator.new(data: "[S [*|b|* x]]", format: "svg").draw_svg
    assert_includes out, "stroke-width:3.2" # 32 * (5% + 5%)
  end

  def test_out_of_range_values_are_rejected
    e = begin
      RSyntaxTree::RSGenerator.new(data: "[S a]", linewidth: 0.25)
      nil
    rescue RSTError => err
      err
    end
    assert_equal :invalid_option, e.code
  end

  def test_hatch_follows_the_type_size
    out = RSyntaxTree::RSGenerator.new(data: "[S [{/} x]]", format: "svg").draw_svg
    assert_includes out, 'width="10.0" height="10.0"'   # 32 * 0.3125
    assert_includes out, 'stroke-width="4.0"'           # 32 * 0.125
  end

  def test_dashes_follow_the_type_size
    out = RSyntaxTree::RSGenerator.new(data: "[S [NP what+1] [VP [V see] [NP+1 t]]]", format: "svg").draw_svg
    assert_includes out, "stroke-dasharray='8.0 8.0'"   # fontsize / 4
  end

  def test_tikz_edge_width_is_in_em
    tikz = RSyntaxTree::RSGenerator.new(data: "[S [NP a] [VP b]]").draw_tikz
    assert_includes tikz, "edge={line width=0.05em}"
    tikz2 = RSyntaxTree::RSGenerator.new(data: "[S [NP a] [VP b]]", linewidth: 2).draw_tikz
    assert_includes tikz2, "edge={line width=0.1em}"
  end

  def test_cli_accepts_the_new_scale
    _out, _err, status = Open3.capture3("ruby", BIN_PATH, "-i", "0.5", "--validate", "[S a]")
    assert status.success?
    _out, err, status = Open3.capture3("ruby", BIN_PATH, "-i", "4", "--validate", "[S a]")
    refute status.success?
    assert_includes err, "0.5-3.0"
  end
end
