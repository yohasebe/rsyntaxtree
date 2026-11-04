# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"
require "timeout"

require_relative "../lib/rsyntaxtree"

# A movement path runs out from the side the words are on — below a tree
# drawn top to bottom, above one drawn bottom to top, to the right of one
# drawn left to right — and its rail runs past every label across its span,
# not only past its two ends.
class PathRailTest < Minitest::Test
  # The path runs from the first leaf to the last, so every label stands
  # across its span; "child" stands farther out than either end.
  TREE = "[CP [DP what+>1] [C' [C did] [TP [DP [D the] [NP [N [N child]]]] [T' [T t] [VP [V find] [DP t+1]]]]]]"

  def rail(svg, direction)
    d = svg[/<path d='([^']+)'[^>]*marker-end/, 1]
    points = d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
    case direction
    when "ltr" then points.map(&:first).max
    when "btt" then points.map(&:last).min
    else points.map(&:last).max
    end
  end

  %w[ttb btt ltr].each do |direction|
    %w[off words].each do |mode|
      define_method "test_the_rail_clears_every_label_#{direction}_#{mode}" do
        options = { data: TREE, direction: direction, leaf_align: mode }
        at = rail(RSyntaxTree::RSGenerator.new(options).draw_svg, direction)
        nodes = JSON.parse(RSyntaxTree::RSGenerator.new(options.merge(format: "json")).draw_json)["nodes"]

        refute_empty nodes
        nodes.each do |n|
          pos = n["position"]
          label = n["label"]["raw"]
          case direction
          when "ltr" then assert_operator at, :>, pos["x"] + pos["content_width"], label
          when "btt" then assert_operator at, :<, pos["y"], label
          else assert_operator at, :>, pos["y"] + pos["content_height"], label
          end
        end
      end
    end
  end

  # Two paths over overlapping spans run on rails of their own, the wider
  # outside the narrower, even where the same label sets how far out both go.
  NESTED = "[S [A a+1] [B b+2] [C [D d]] [E e+2] [F [G f+1]]]"

  %w[ttb btt].each do |direction|
    define_method "test_overlapping_paths_keep_rails_of_their_own_#{direction}" do
      svg = RSyntaxTree::RSGenerator.new(data: NESTED, direction: direction).draw_svg
      rails = svg.scan(/<path d='([^']+)'[^>]*stroke-dasharray/).flatten.map do |d|
        points = d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
        xs = points.map(&:first)
        ys = points.map(&:last)
        [xs.max - xs.min, direction == "btt" ? ys.min : ys.max]
      end
      narrow, wide = rails.sort_by(&:first).map(&:last)

      assert_equal 2, rails.size
      if direction == "btt"
        assert_operator wide, :<, narrow
      else
        assert_operator wide, :>, narrow
      end
    end
  end

  # A rail moved one spacing past another can measure a hair under that
  # spacing; it is still clear, and the figure is still drawn.
  {
    "nested" => ["[S [a+1] [b+2] [c+2] [d+1]]", {}],
    "nested_btt" => ["[S [a+1] [b+2] [c+2] [d+1]]", { direction: "btt" }],
    "arrowed" => ["[S [a+>1] [b+>2] [c+>2] [d+>1]]", {}],
    "shared_end" => ["[S [a+1+2] [b+2] [c+1]]", {}]
  }.each do |name, (tree, options)|
    define_method "test_rails_one_spacing_apart_are_clear_#{name}" do
      svg = Timeout.timeout(10) do
        RSyntaxTree::RSGenerator.new({ data: tree, hspacing: 1.5 }.merge(options)).draw_svg
      end

      assert_equal 2, svg.scan(/<path d='/).size
    end
  end

  # Above the words, the rail is past the top of the tree, and the canvas
  # grows to hold it.
  def test_the_canvas_holds_a_rail_above_the_tree
    svg = RSyntaxTree::RSGenerator.new(data: TREE, direction: "btt").draw_svg
    top = svg[/viewBox="[^,]+, ([-\d.]+)/, 1].to_f

    assert_operator top, :<, rail(svg, "btt")
  end
end
