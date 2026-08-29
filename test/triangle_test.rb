# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# `^` asks for a triangle over a leaf. It may be written at the head of the
# node's label or at the head of the leaf's own text — `[^NP cats]` and
# `[NP ^cats]` — and the manual, the notation reference and the gallery all use
# both. Only the first was drawn: the second lost its caret to the parser and
# then a bar was drawn under it, so `[NP ^cats]` and `[NP cats]` came out the
# same figure and nothing said why.
#
# What made it quiet is that the flag was read in two places that disagreed.
# The layout reads the leaf's own flag — a leaf marked this way keeps the gap a
# triangle needs even when connectors are off — and only the drawing read the
# parent's. So the space was there and nothing was put in it.
class TriangleTest < Minitest::Test
  def svg(data, extra = {})
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(extra).merge(data: data)).draw_svg
  end

  def triangles(data, extra = {})
    svg(data, extra).scan("<polygon").size
  end

  # The two places a caret may be written mean the same thing.
  def test_the_caret_draws_a_triangle_written_either_way
    assert_equal 1, triangles("[NP ^cats]"), "a caret on the leaf"
    assert_equal 1, triangles("[^NP cats]"), "a caret on the node"
    assert_equal 0, triangles("[NP cats]"), "no caret, one word: a bar"
  end

  # Whitespace in a leaf makes a phrase of it, so `auto` would draw a triangle
  # for these whether or not the caret worked. A single word is the case that
  # tells the two apart, and it is the case the caret is written for.
  def test_a_phrase_is_a_triangle_without_being_asked
    assert_equal 1, triangles("[NP two words]")
  end

  # `auto` reads whitespace; `bar` and `nothing` do not, and the caret is the only
  # way to ask for a triangle under either.
  def test_the_caret_is_honoured_whatever_the_leaf_style
    %w[auto bar nothing].each do |style|
      assert_equal 1, triangles("[NP ^cats]", leafstyle: style),
                   "leafstyle #{style}: a caret on the leaf"
      assert_equal 0, triangles("[NP cats]", leafstyle: style),
                   "leafstyle #{style}: no caret"
    end
  end

  # The caret marks the connector, not the text. It is taken out of the label.
  def test_the_caret_is_not_drawn
    refute_includes svg("[NP ^cats]"), "^cats"
    assert_includes svg("[NP ^cats]"), "cats"
  end

  # Under `nothing` a leaf is otherwise pulled up against its node, and a triangle
  # needs the room.
  def test_a_marked_leaf_keeps_the_room_a_triangle_needs
    marked = svg("[NP ^cats]", leafstyle: "nothing")[/<svg[^>]*height="([\d.]+)/, 1].to_f
    plain = svg("[NP cats]", leafstyle: "nothing")[/<svg[^>]*height="([\d.]+)/, 1].to_f
    assert marked > plain, "a triangle asks for more height than a leaf with nothing over it"
  end

  # The manual says the two placements ask for the same thing, so they have to
  # produce the same figure — not merely both a triangle. They did not under
  # `nothing`: the room a triangle needs was decided from the leaf's own mark
  # alone, so a caret on the node drew its triangle into a gap that had been
  # closed, and it came out a sliver. The same question, asked two ways again.
  def test_the_two_placements_draw_the_same_figure
    %w[auto bar nothing].each do |style|
      assert_equal svg("[S [NP ^cats] [VP sit]]", leafstyle: style),
                   svg("[S [^NP cats] [VP sit]]", leafstyle: style),
                   "leafstyle #{style}: the two placements draw different figures"
    end
  end

  # A caret on an internal node is that node's own mark and belongs to the leaf
  # under it, not to the branch that reaches it.
  def test_a_caret_on_a_node_marks_that_nodes_own_leaf
    # Two triangles, not three: NP over "cats", VP over "sat there" — the
    # branch from S to VP is a line.
    assert_equal 2, triangles("[S [NP ^cats] [^VP sat there]]")
  end

  # LSIF states what the figure was drawn with, so it has to say triangle here
  # too. It carries its own copy of this decision.
  def test_json_records_the_triangle
    edges = lambda do |data|
      json = JSON.parse(RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: data)).draw_json)
      (json.dig("graphs", 0, "edges") || json["edges"]).map { |e| e["connector"] }
    end
    assert_equal ["triangle"], edges.call("[NP ^cats]")
    assert_equal ["line"], edges.call("[NP cats]")
  end

  # A triangle points at the parent, and bottom-to-top is where the parent is
  # not below. Drawn as though it always were, the figure folded through
  # itself: the base struck through the leaf and the apex through the node.
  # No gallery figure has ever carried one — every bottom-to-top example is a
  # derivation, which draws rules instead of connectors — so nothing said.
  def test_a_triangle_points_the_right_way_bottom_to_top
    %w[ttb btt].each do |direction|
      svg = RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(
        data: "[S [NP ^the<>big<>dog] [VP barks]]", direction: direction
      )).draw_svg
      pts = svg[/<polygon[^>]*points='([^']+)'/, 1]
                .split(/\s+/).each_slice(2).map { |a, b| [a.to_f, b.to_f] }
      area = (pts[0][0] * (pts[1][1] - pts[2][1]) +
              pts[1][0] * (pts[2][1] - pts[0][1]) +
              pts[2][0] * (pts[0][1] - pts[1][1])).abs / 2
      assert_operator area, :>, 1000, "#{direction}: the triangle is flat"

      baselines = svg.scan(/<tspan[^>]*y='([\d.]+)'/).flatten.map(&:to_f).uniq.sort
      leaf, node = direction == "btt" ? [baselines.first, baselines[1]] : [baselines.last, baselines[1]]
      base_y = pts.map(&:last).sort[1] # the two equal corners
      apex_y = pts.map(&:last).minmax.find { |y| pts.map(&:last).count(y) == 1 }
      if direction == "btt"
        assert_operator base_y, :>, leaf, "btt: the base cuts through the leaf"
        assert_operator apex_y, :<, node, "btt: the apex cuts through the node"
      else
        assert_operator base_y, :<, leaf, "ttb: the base cuts through the leaf"
        assert_operator apex_y, :>, node, "ttb: the apex cuts through the node"
      end
    end
  end
end
