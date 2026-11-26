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

  # Plain labels in the default layout: a preterminal over its one word.
  def test_an_only_child_hangs_straight_in_every_layout
    tree = "[S [NP [D The] [N cat]] [VP [V sat] [PP [P on] [NP [D the] [N mat]]]]]"
    %w[off low medium high symmetric].each do |tidy|
      %w[sans serif].each do |font|
        svg = RSyntaxTree::RSGenerator.new(data: tree, tidy: tidy, fontstyle: font, format: "svg").draw_svg
        slanted = svg.scan(/<line\b[^>]*x1='([\d.]+)' y1='[\d.]+' x2='([\d.]+)'/).filter_map do |a, b|
          dx = (a.to_f - b.to_f).abs
          dx if dx.positive? && dx < 2
        end
        assert_empty slanted, "tidy #{tidy}, #{font}: connectors off vertical by #{slanted.uniq.inspect}"
      end
    end
  end

  # Three or five children whose outer labels differ in width: the middle
  # one hangs straight below the parent, in every layout and direction. Each
  # parent with an odd number of children is checked against its own middle
  # child, so a lean of any size is caught and nothing else is mistaken for
  # one.
  def test_a_middle_child_hangs_straight
    require "json"
    trees = ["[S [A [B u] [C v] [D w]] [E x]]", "[S [x] [D x] [x]]", "[S [Wa w] [M m] [Ia i]]",
             "[S [A [Bee b] [C c] [D d] [Eee e] [F f]]]"]
    trees.each do |tree|
      %w[off low medium high symmetric].each do |tidy|
        %w[ttb btt].each do |direction|
          nodes = JSON.parse(RSyntaxTree::RSGenerator.new(data: tree, tidy: tidy, direction: direction,
                                                          format: "json").draw_json)["nodes"]
          by_id = nodes.to_h { |n| [n["id"], n] }
          centre = ->(n) { n["position"]["x"] + (n["position"]["content_width"] / 2.0) }
          parents = nodes.select { |n| n["children"].to_a.size.odd? && n["children"].size > 1 }

          refute_empty parents, tree
          parents.each do |parent|
            mid = by_id[parent["children"][parent["children"].size / 2]]
            assert_in_delta centre.call(parent), centre.call(mid), 1e-6,
                            "#{tree}, tidy #{tidy}, #{direction}: #{parent.dig("label", "raw")} over its middle child"
          end
        end
      end
    end
  end

  # Moving a middle child under its parent takes nothing from anything else:
  # the words keep their order, and a pair joined by a line keeps the room
  # spread for its arrowheads.
  def test_hanging_a_middle_child_disturbs_nothing_else
    require "json"
    centre = ->(n) { n["position"]["x"] + (n["position"]["content_width"] / 2.0) }
    nodes = JSON.parse(RSyntaxTree::RSGenerator.new(
      data: "[R [x] [M [D [a] [w] [x] [x]] [i] [i [a] [Wide [text] [text] [j]]]] [l]]",
      tidy: "medium", hspacing: 0.5, format: "json"
    ).draw_json)["nodes"]
    words = nodes.select { |n| n["children"].to_a.empty? }

    assert_equal words.map { |n| n.dig("label", "raw") }, words.sort_by { |n| centre.call(n) }.map { |n| n.dig("label", "raw") }

    linked = "[S [##i] [##M+-<1] [##x+->1]]"
    gap = lambda do |opts|
      found = JSON.parse(RSyntaxTree::RSGenerator.new(data: linked, format: "json", **opts).draw_json)["nodes"]
      m = found.find { |n| n.dig("label", "raw").include?("M") }["position"]
      x = found.find { |n| n.dig("label", "raw").include?("x") }["position"]
      x["x"] - m["x"] - m["content_width"]
    end
    # Left to right, the arrowheads are sized from the gap as drawn.
    tips = lambda do
      svg = RSyntaxTree::RSGenerator.new(data: "[R [x] [##M+-<1 [LL m] [D x]] [##i+->1]]",
                                         direction: "ltr", tidy: "low", hspacing: 2, format: "svg").draw_svg
      svg.scan(/<polygon points='([-\d.]+),([-\d.]+) /).map { |x, y| [x.to_f, y.to_f] }
    end
    # Shades of sibling subtrees that only touched stay apart.
    shaded = [["[R [%M [%label [%label a]]] [%W b] [%M [%M [%J c]]]]", 0.5],
              ["[R [%W [%M [%label [%PP a]]]] [%i [%M b]] [%D [%J [%M [%D c]]]]]", 0.75],
              ["[R [%Wide [%x [%mm a]]] [%J b] [%W [%Wide [%x c]]]]", 0.5],
              ["[R [%PP [%i [%Wide a]]] [%mm b] [%x [%PP [%i c]]]]", 0.75]]
    shades = lambda do
      shaded.map do |data, hspacing|
        svg = RSyntaxTree::RSGenerator.new(data: data, tidy: "off", hspacing: hspacing, format: "svg").draw_svg
        svg.scan(/<rect x='([-\d.e]+)' y='[-\d.e]+' width='([\d.e]+)'[^>]*fill-opacity/).map { |x, w| [x.to_f, x.to_f + w.to_f] }
      end
    end
    with = [gap.call({}), tips.call, shades.call]
    RSyntaxTree::BaseGraph.alias_method :hang_middle_children, :align_middle_children
    RSyntaxTree::BaseGraph.define_method(:align_middle_children) { nil }
    without = begin
      [gap.call({}), tips.call, shades.call]
    ensure
      RSyntaxTree::BaseGraph.alias_method :align_middle_children, :hang_middle_children
    end
    assert_in_delta without[0], with[0], 1e-6, "the linked pair lost the room spread for its arrowheads"
    refute_empty with[1]
    span = ->(points) { points.map(&:last).max - points.map(&:last).min }
    assert_in_delta span.call(without[1]), span.call(with[1]), 1e-6, "a link drawn left to right changed length"
    # Shades that neither hold the other must not share any width.
    crossing = lambda do |rects|
      rects.combination(2).count do |(a_left, a_right), (b_left, b_right)|
        nested = (a_left <= b_left && b_right <= a_right) || (b_left <= a_left && a_right <= b_right)
        !nested && [a_right, b_right].min - [a_left, b_left].max > 0.01
      end
    end
    with[2].zip(without[2], shaded) do |moved, kept, (data, _)|
      refute_empty moved
      refute_operator crossing.call(moved), :>, crossing.call(kept), "#{data}: sibling shades came to overlap"
    end
  end
end
