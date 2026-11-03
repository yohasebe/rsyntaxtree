# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# A polyline joins a node to each of its children through one rail: every
# child's line leaves the node at the same place and runs along the same
# rail before turning to it. A joint — a node labelled only `<>`, written by
# hand or inserted by leaf alignment — is a child like any other, so its line
# has to share that rail with its siblings' rather than run at a height of
# its own.
class PolylineJointTest < Minitest::Test
  TREES = {
    "written" => ["[S [A a] [<> [B b]] [C [D d]]]", {}],
    "words" => ["[S [A a] [B [C [D d]]] [E [F f]]]", { leaf_align: "words" }],
    "subtrees" => ["[S [A a] [B [C [D d]]] [E [F f]]]", { leaf_align: "subtrees" }]
  }.freeze

  # The rail of each polyline: the coordinate its middle segment runs along,
  # grouped by the parent the polyline leaves. A polyline's points are the
  # child's end, the two corners and the parent's end.
  def rails(svg, direction)
    groups = Hash.new { |h, k| h[k] = [] }
    svg.scan(/<polyline[^>]*points='([^']+)'/).flatten.each do |points|
      chi_x, chi_y, mid_x, mid_y, _, _, par_x, par_y = points.split.map(&:to_f)
      next if [chi_x, chi_y, mid_x, mid_y, par_x, par_y].any?(&:nil?)

      groups[[par_x.round(2), par_y.round(2)]] << (direction == "ltr" ? mid_x : mid_y).round(2)
    end
    groups
  end

  TREES.each do |name, (tree, options)|
    %w[ttb btt ltr].each do |direction|
      define_method "test_#{name}_joints_share_the_rail_#{direction}" do
        svg = RSyntaxTree::RSGenerator.new({ data: tree, polyline: "on", direction: direction }.merge(options)).draw_svg
        groups = rails(svg, direction)

        refute_empty groups
        groups.each do |parent, positions|
          assert_equal 1, positions.uniq.size, "rails under the node at #{parent}: #{positions.uniq}"
        end
      end
    end
  end

  # An enclosed child is met at the box drawn round it, so its rail runs
  # halfway between the parent's end and the box rather than by the ink of
  # the row it stands in — here a row that also holds a plain label.
  def test_an_enclosed_child_keeps_its_rail_halfway_to_the_box
    svg = RSyntaxTree::RSGenerator.new(data: "[S [##A a] [##B b] [C c]]", polyline: "on").draw_svg
    lines = svg.scan(/<polyline[^>]*points='([^']+)'/).flatten.map { |points| points.split.map(&:to_f) }

    refute_empty lines
    lines.each do |_, chi_y, _, mid_y, _, _, _, par_y|
      assert_in_delta (chi_y + par_y) / 2, mid_y, 0.01
    end
  end
end
