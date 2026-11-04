# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"

# Drawn left to right, a level is as wide as the labels standing in it.
# Aligned leaves stand in one column, and so does every level above them.
class LtrLeafAlignTest < Minitest::Test
  TREE = "[CP [DP what+>1] [C' [C did] [TP [DP [D the] [NP [N child]]] [T' [T t] [VP [V find] [DP t+1]]]]]]"

  def nodes(options)
    json = RSyntaxTree::RSGenerator.new({ data: TREE, direction: "ltr", format: "json" }.merge(options)).draw_json
    JSON.parse(json)["nodes"]
  end

  %w[words subtrees].each do |mode|
    define_method "test_#{mode}_stand_in_one_column" do
      all = nodes(leaf_align: mode)
      leaves = all.select { |n| n["type"] == "leaf" }

      assert_operator leaves.size, :>, 1
      assert_equal 1, leaves.map { |n| n["position"]["x"] }.uniq.size

      all.group_by { |n| n["level"] }.each do |level, row|
        assert_equal 1, row.map { |n| n["position"]["x"] }.uniq.size, "level #{level}"
      end
    end
  end
end
