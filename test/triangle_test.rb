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

  # `auto` reads whitespace; `bar` and `none` do not, and the caret is the only
  # way to ask for a triangle under either.
  def test_the_caret_is_honoured_whatever_the_leaf_style
    %w[auto bar nothing none].each do |style|
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

  # Under `none` a leaf is otherwise pulled up against its node, and a triangle
  # needs the room. This is the half of the rule that was right all along.
  def test_a_marked_leaf_keeps_the_room_a_triangle_needs
    marked = svg("[NP ^cats]", leafstyle: "nothing")[/<svg[^>]*height="([\d.]+)/, 1].to_f
    plain = svg("[NP cats]", leafstyle: "nothing")[/<svg[^>]*height="([\d.]+)/, 1].to_f
    assert marked > plain, "a triangle asks for more height than a leaf with nothing over it"
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
  def test_lsif_records_the_triangle
    edges = lambda do |data|
      json = JSON.parse(RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: data)).draw_lsif)
      (json.dig("graphs", 0, "edges") || json["edges"]).map { |e| e["connector"] }
    end
    assert_equal ["triangle"], edges.call("[NP ^cats]")
    assert_equal ["line"], edges.call("[NP cats]")
  end
end
