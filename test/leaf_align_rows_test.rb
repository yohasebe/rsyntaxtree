# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"

# Aligned leaves share a depth, and every depth is drawn as one row: a label
# of two lines, a leaf pulled up under leafstyle nothing, or — drawn left to
# right — a level as wide as its widest label leaves no word out of line.
class LeafAlignRowsTest < Minitest::Test
  TREES = {
    "a moved phrase" => ["[CP [DP what+>1] [C' [C did] [TP [DP [D the] [NP [N child]]] [T' [T t] [VP [V find] [DP t+1]]]]]]", {}],
    "a label of two lines" => ['[S [A\nX a] [B [C c]]]', {}],
    "leaves pulled up" => ["[S [A a] [B [b] [c]]]", { leafstyle: "nothing" }]
  }.freeze

  def nodes(tree, options)
    json = RSyntaxTree::RSGenerator.new({ data: tree, format: "json" }.merge(options)).draw_json
    JSON.parse(json)["nodes"]
  end

  TREES.each do |what, (tree, extra)|
    %w[ttb btt ltr].each do |direction|
      %w[words subtrees].each do |mode|
        define_method "test_#{what.tr(" ", "_")}_#{direction}_#{mode}" do
          all = nodes(tree, extra.merge(direction: direction, leaf_align: mode))
          axis = direction == "ltr" ? "x" : "y"
          leaves = all.select { |n| n["type"] == "leaf" }

          assert_operator leaves.size, :>, 1
          assert_equal 1, leaves.map { |n| n["position"][axis] }.uniq.size

          # Turned over, a row is set against its labels' lower edges.
          edge = if direction == "btt"
                   ->(n) { (n["position"]["y"] + n["position"]["content_height"]).round(3) }
                 else
                   ->(n) { n["position"][axis] }
                 end
          all.group_by { |n| n["level"] }.each do |level, row|
            assert_equal 1, row.map(&edge).uniq.size, "level #{level}"
          end
        end
      end
    end
  end
end
