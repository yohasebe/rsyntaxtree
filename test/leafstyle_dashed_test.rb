# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# leafstyle `dashed` draws the line down to each word dashed, and every other
# line as `bar` would.
class LeafstyleDashedTest < Minitest::Test
  TREE = "[S [NP Kim] [VP [V saw] [NP [Det the] [N dog]]]]"

  def svg(data, extra = {})
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(leafstyle: "dashed").merge(extra).merge(data: data)).draw_svg
  end

  def connectors(svg)
    svg.scan(/<(?:line|polyline) style='[^']*stroke-linejoin:round; stroke-linecap:round;'[^>]*>/)
  end

  %w[ttb ltr].each do |direction|
    [false, true].each do |polyline|
      define_method "test_only_the_lines_to_words_are_dashed_#{direction}_#{polyline ? "polyline" : "straight"}" do
        lines = connectors(svg(TREE, direction: direction, polyline: polyline))
        dashed, solid = lines.partition { |l| l.include?("stroke-dasharray") }

        assert_equal 4, dashed.size, "one dashed line to each of the four words"
        assert_equal 6, solid.size, "the six lines between nodes stay solid"
      end
    end
  end

  # Leaf alignment draws a line to a word in pieces, through the joints it
  # inserts. Each piece takes up the dash where the piece above left off.
  def test_the_dash_runs_on_through_inserted_joints
    out = svg("[S [NP Kim] [VP [V saw] [NP [Det the] [N dog]]]]", leaf_align: "words")
    pieces = connectors(out).select { |l| l.include?("stroke-dasharray") }.map do |l|
      x, top, bottom = %w[x1 y1 y2].map { |k| l[/ #{k}='([-\d.]+)'/, 1].to_f }
      { x: x, top: top, bottom: bottom, from: l[/stroke-dashoffset='([-\d.]+)'/, 1].to_f }
    end
    chains = pieces.group_by { |p| p[:x].round(3) }.values.select { |c| c.size > 1 }

    refute_empty chains, "a word lowered through joints"
    chains.each do |chain|
      run = 0.0
      chain.sort_by { |p| p[:top] }.each do |piece|
        assert_operator piece[:top], :<, piece[:bottom], "laid from the parent down"
        assert_in_delta run, piece[:from], 1e-3
        run += piece[:bottom] - piece[:top]
      end
    end
  end

  def test_a_triangle_stays_solid
    out = svg("[S [NP ^the dog] [VP barked]]")

    assert_equal 1, out.scan("<polygon").size
    refute_match(/<polygon[^>]*stroke-dasharray/, out)
    assert_equal 1, connectors(out).count { |l| l.include?("stroke-dasharray") }, "only the bar to barked"
  end

  def test_the_json_marks_the_dashed_edges
    json = JSON.parse(RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: TREE, leafstyle: "dashed", format: "json")).draw_json)
    leaves = json["nodes"].reject { |n| n["children"]&.any? }.map { |n| n["id"] }
    dashed = json["edges"].select { |e| e["dashed"] }

    assert_equal 4, dashed.size
    dashed.each { |e| assert_includes leaves, e["to"] }
  end

  def test_the_tikz_dashes_the_edges_to_words
    tex = RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: TREE, leafstyle: "dashed", format: "tikz")).draw_tikz

    assert_equal 4, tex.scan("edge+=dashed").size
    assert_includes tex, "[Kim, edge+=dashed]"
  end

  # Under leaf alignment the edge down to a word runs through joints, and
  # forest gives each piece to the node below it: every piece is dashed.
  def test_the_tikz_dashes_every_piece_through_joints
    tex = RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: "[S [N x] [VP [V y]]]", leafstyle: "dashed",
                                                          leaf_align: "words", format: "tikz")).draw_tikz

    assert_match(/\[N\s+\[, edge\+=dashed\s+\[x, edge\+=dashed\]/, tex)
    assert_equal 3, tex.scan("edge+=dashed").size
  end
end
