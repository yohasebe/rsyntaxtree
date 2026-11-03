# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# A movement path that ends in an arrowhead leaves the rail by a run that
# holds the head and a stem before the turn. The rail used to clear the
# lower end by a fixed bulge, so an arrowhead on that end — on either end
# once the terminals stand on one row — sat against the corner.
class PathArrowTest < Minitest::Test
  LEVEL = "[CP [DP what+>1] [C' [C did] [TP [DP [D the] [NP [N child]]] [T' [T t] [VP [V find] [DP t+1]]]]]]"
  LOWER_HEAD = "[S [NP t+1] [VP [V saw] [NP [D the] [NP [N one+>1]]]]]"

  def arrowhead(svg)
    svg[/<marker id="arrow"[^>]*markerWidth="([\d.]+)"/, 1].to_f
  end

  # The run from the head's end of the path to the rail, along the axis the
  # path leaves the tree by: down for a tree drawn top to bottom, right for
  # one drawn left to right.
  def arrow_run(svg, direction)
    d = svg[/<path d='([^']+)'[^>]*marker-end/, 1]
    points = d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
    axis = direction == "ltr" ? 0 : 1
    rail = points.map { |point| point[axis] }.max
    rail - points.last[axis]
  end

  { "level ends" => [LEVEL, { leaf_align: "words" }],
    "the head on the lower end" => [LOWER_HEAD, {}] }.each do |what, (tree, options)|
    %w[ttb ltr].each do |direction|
      define_method "test_#{what.tr(' ', '_')}_leave_a_stem_behind_the_head_#{direction}" do
        svg = RSyntaxTree::RSGenerator.new({ data: tree, direction: direction }.merge(options)).draw_svg
        head = arrowhead(svg)

        assert head.positive?
        assert_operator arrow_run(svg, direction) - head, :>=, head
      end
    end
  end
end
