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

  # A label where one path ends and the next begins sends each from the side
  # it heads for, so neither path crosses the other.
  # Each tree is drawn with the shorter path on either side, as the shorter
  # is drawn first and the other has to find room at the shared label.
  CHAIN = {
    "shorter_left" => "[S [a+>1] [b+1+>2] [c] [d] [e+2]]",
    "shorter_right" => "[S [a+>1] [b] [c] [d+1+>2] [e+2]]",
    "embedded" => "[CP [Wh what+>1] [C' [C can] [S [NP Tom] [VP [V remember] " \
                  "[CP [Wh \\_\\_+1+>2] [C' [C that] [S [NP Lucy] [VP [V was reading] [NP \\_\\_+2]]]]]]]]]"
  }.freeze

  def strokes(svg)
    svg.scan(/<path d='([^']+)'/).flatten.map do |d|
      d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).each_cons(2).to_a
    end
  end

  def meet?((p1, p2), (q1, q2))
    turn = ->(a, b, c) { ((b[0] - a[0]) * (c[1] - a[1])) - ((b[1] - a[1]) * (c[0] - a[0])) }
    within = ->(a, b, c) { c[0].between?(*[a[0], b[0]].minmax) && c[1].between?(*[a[1], b[1]].minmax) }
    d1 = turn.call(q1, q2, p1)
    d2 = turn.call(q1, q2, p2)
    d3 = turn.call(p1, p2, q1)
    d4 = turn.call(p1, p2, q2)
    return true if (d1 * d2).negative? && (d3 * d4).negative?

    [[d1, q1, q2, p1], [d2, q1, q2, p2], [d3, p1, p2, q1], [d4, p1, p2, q2]].any? do |d, a, b, c|
      d.zero? && within.call(a, b, c)
    end
  end

  CHAIN.each do |name, tree|
    %w[ttb btt ltr].each do |direction|
      %w[off words].each do |mode|
        define_method "test_chained_paths_do_not_cross_#{name}_#{direction}_#{mode}" do
          svg = RSyntaxTree::RSGenerator.new(data: tree, direction: direction, leaf_align: mode).draw_svg
          first, second = strokes(svg)

          assert second, "two paths"
          first.each do |a|
            second.each { |b| refute meet?(a, b), "#{a.inspect} meets #{b.inspect}" }
          end
        end
      end
    end

    # Two paths that only meet at a label run on one level: once their ends
    # there are spread apart, nothing of one is in the other's way.
    %w[ttb btt].each do |direction|
      define_method "test_chained_paths_share_a_level_#{name}_#{direction}" do
        svg = RSyntaxTree::RSGenerator.new(data: tree, direction: direction, leaf_align: "words").draw_svg
        levels = strokes(svg).map do |segments|
          ys = segments.flatten(1).map(&:last)
          direction == "btt" ? ys.min : ys.max
        end

        assert_equal 2, levels.size
        assert_in_delta levels[0], levels[1], 1e-6
      end
    end
  end

  # However many paths meet at one label, their ends stay on it: off the
  # labels beside it, and inside the canvas.
  CROWDED = "[S #{(1..10).map { |n| "[a+>#{n}]" }.join(" ")} [i+#{(1..10).to_a.join("+")}]]"

  %w[ttb btt ltr].each do |direction|
    define_method "test_crowded_ends_stay_on_their_label_#{direction}" do
      options = { data: CROWDED, direction: direction }
      svg = RSyntaxTree::RSGenerator.new(options).draw_svg
      nodes = JSON.parse(RSyntaxTree::RSGenerator.new(options.merge(format: "json")).draw_json)["nodes"]
      shared = nodes.find { |n| n["label"]["raw"] == "i" }["position"]
      left, top, width, height = svg[/viewBox="([^"]+)"/, 1].split(/[ ,]+/).map(&:to_f)
      centre = [shared["x"] + (shared["content_width"] / 2.0), shared["y"] + (shared["content_height"] / 2.0)]
      ends = strokes(svg).map do |segments|
        [segments.first.first, segments.last.last].min_by { |x, y| Math.hypot(x - centre[0], y - centre[1]) }
      end

      assert_equal 10, ends.size
      ends.each do |x, y|
        assert_operator x, :>=, left
        assert_operator x, :<=, left + width
        assert_operator y, :>=, top
        assert_operator y, :<=, top + height
        if direction == "ltr"
          assert_operator y, :>=, shared["y"], "on the label"
          assert_operator y, :<=, shared["y"] + shared["content_height"], "on the label"
        else
          assert_operator x, :>=, shared["x"], "on the label"
          assert_operator x, :<=, shared["x"] + shared["content_width"], "on the label"
        end
      end
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
