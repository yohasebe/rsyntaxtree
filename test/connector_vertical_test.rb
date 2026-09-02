# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rsyntaxtree"

# A box's centre is horizontal_indent + content_width / 2. content_width is
# an integer, so dividing by 2 without a fractional part floors it, and a
# connector drawn between two boxes floored its two ends independently: when
# the boxes' widths had different parity the ends landed half a pixel apart
# and the connector, meant to be vertical, came out slanted. Every centre is
# now taken in floating point, so the two ends meet.
class ConnectorVerticalTest < Minitest::Test
  # A row of preterminals over single words, each preterminal a feature
  # matrix so the box widths vary. The single-word connectors should be
  # vertical whatever the parity of the two boxes works out to, which is why
  # the check runs across a range of sizes: at some size the old floor split
  # a pair, and the point is that no size does now.
  TREE = "[S [NP [#(pos\\tDET#) the]] [NP [#(pos\\tNOUN#) river]] " \
         "[NP [#(pos\\tADP#) near]] [NP [#(pos\\tADJ#) old]] [NP [#(pos\\tPRON#) she]]]"

  # The horizontal offset between the two ends of each connector that runs
  # (nearly) straight down — a single child under its parent.
  def vertical_connector_dxs(svg)
    svg.scan(/<polyline[^>]*points='([^']*)'/).filter_map do |coords|
      pts = coords[0].scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
      next if pts.size < 2

      dx = (pts.first[0] - pts.last[0]).abs
      dy = (pts.first[1] - pts.last[1]).abs
      dx if dy > 20 && dx < 5 # a downward run, not a wide rail to an outer child
    end
  end

  def test_single_child_connectors_are_exactly_vertical_at_every_size
    (10..16).each do |fs|
      svg = RSyntaxTree::RSGenerator.new(
        data: TREE, hyphen: "literal", fontsize: fs,
        polyline: "on", tidy: "medium", format: "svg"
      ).draw_svg
      dxs = vertical_connector_dxs(svg)
      refute_empty dxs, "no vertical connector found at fontsize #{fs}"
      slanted = dxs.reject { |dx| dx < 0.001 }
      assert_empty slanted,
                   "fontsize #{fs}: connectors off vertical by #{slanted.map { |d| d.round(2) }.uniq.inspect}"
    end
  end

  # The same in straight-line mode (no polyline), where the connector is one
  # <line> and its two ends are x1/x2.
  def test_straight_connectors_are_exactly_vertical
    svg = RSyntaxTree::RSGenerator.new(
      data: TREE, hyphen: "literal", fontsize: 13, tidy: "medium", format: "svg"
    ).draw_svg
    dxs = svg.scan(/<line\b[^>]*>/).filter_map do |line|
      x1 = line[/\bx1='([\d.]+)'/, 1]&.to_f
      x2 = line[/\bx2='([\d.]+)'/, 1]&.to_f
      y1 = line[/\by1='([\d.]+)'/, 1]&.to_f
      y2 = line[/\by2='([\d.]+)'/, 1]&.to_f
      next unless x1 && x2 && y1 && y2

      (x1 - x2).abs if (y1 - y2).abs > 20 && (x1 - x2).abs < 5
    end
    slanted = dxs.reject { |dx| dx < 0.001 }
    assert_empty slanted, "straight connectors off vertical by #{slanted.map { |d| d.round(2) }.uniq.inspect}"
  end
end
