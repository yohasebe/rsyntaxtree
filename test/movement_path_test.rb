# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# A movement path runs from one node, out past the tree, and back to another.
# It used to be three separate lines meeting at right angles, which meant the
# dash pattern restarted at every turn and the arrowhead belonged to whichever
# line happened to finish last. It is one stroke now, with the corners eased.
class MovementPathTest < Minitest::Test
  def svg(data, extra = {})
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(extra).merge(data: data)).draw_svg
  end

  # The paths a figure draws for movement, as their `d` strings. A tree draws
  # other paths — arrowheads, enclosures — so these are picked out by the marker
  # or the dash that only a movement path carries.
  def movement_paths(svg)
    svg.scan(%r{<path d='([^']+)'[^>]*/>}).flatten.select { |d| d.count("L") >= 2 }
  end

  # Every coordinate pair of a path, in the order it is drawn. `Q` carries two
  # pairs — the corner it turns about and the point it lands on — and reading
  # only the first is how this test file first came to pass a path whose turns
  # had eaten the run the arrowhead needed.
  def coordinates(d)
    d.scan(/[-\d.]+,[-\d.]+/).map { |pair| pair.split(",").map(&:to_f) }
  end

  def distance(a, b)
    Math.sqrt(((a[0] - b[0])**2) + ((a[1] - b[1])**2))
  end

  def test_a_path_is_one_stroke_rather_than_three_lines
    d = movement_paths(svg("[S [NP a+1] [VP [V b] [NP c+>1]]]"))
    assert_equal 1, d.size, "one movement path, one stroke"
    assert_equal 1, d.first.scan("M").size, "a single subpath"
  end

  # Two quadratic turns, one at each corner of the U.
  def test_the_corners_are_eased
    d = movement_paths(svg("[S [NP a+1] [VP [V b] [NP c+>1]]]")).first
    assert_equal 2, d.scan("Q").size, "a quarter turn at each corner"
  end

  # `+N` on both ends and no arrow is the dashed, non-directional path. The dash
  # is one attribute of one stroke now, so it runs round the turns.
  def test_a_non_directional_path_is_dashed_end_to_end
    out = svg("[S [NP a+1] [VP [V b] [NP c+1]]]")
    dashed = out.scan(%r{<path[^>]*stroke-dasharray[^>]*/>})
    assert_equal 1, dashed.size, "one dashed stroke, not three"
  end

  # An arrowhead is drawn back along the run it ends, so the turn before it must
  # leave that run its full length. The shorter of the two end runs is only as
  # long as the path's bulge, and at the plain radius it lost half of itself to
  # the turn — putting the head on the curve.
  def test_a_turn_leaves_the_arrowhead_its_run
    out = svg("[S [NP a+1] [VP [V b] [NP c+>1]]]")
    points = coordinates(movement_paths(out).first)
    arrow = out[/id="arrow".*?markerWidth="([\d.]+)"/m, 1].to_f

    assert_operator arrow, :>, 0, "the arrow marker has a size to compare against"
    assert_operator distance(points[-2], points[-1]), :>=, arrow * 0.99,
                    "the run the arrowhead is drawn back along is shorter than the head"
  end

  # Both directions route the same way and are drawn by the same code; ltr sends
  # the path out to the right of the tree instead of below it.
  def test_left_to_right_paths_are_eased_too
    d = movement_paths(svg("[S [NP a+1] [VP [V b] [NP c+>1]]]", direction: "ltr")).first
    refute_nil d, "an ltr figure draws its movement path"
    assert_equal 2, d.scan("Q").size
  end

  # A turn can never eat more than half of either run it joins, so a short run
  # cannot be swallowed and two turns cannot overlap. The run between the two
  # corners is the one to ask about: each turn takes a bite from one end of it,
  # and unclamped the two bites cross.
  def test_a_turn_never_takes_more_than_its_run
    # The dashed form carries no arrowhead, so nothing else is holding the
    # radius down and the clamp is the only thing between a turn and the run it
    # would swallow. Its deepest end run is exactly the path's bulge, which is
    # twice the radius — the boundary case.
    ["[S [NP a+1] [NP b+1]]",
     "[S [NP a+1] [VP [V b] [NP c+1]]]",
     "[S [NP a+1] [VP [V b] [NP c+>1]]]"].each do |data|
      points = coordinates(movement_paths(svg(data, vheight: 0.5)).first)
      # M p0, L t1, Q c1 t2, L t3, Q c2 t4, L p5
      p0, t1, c1, t2, t3, c2, t4, p5 = points

      # A tangent point sits on the run it eases, not past either end of it.
      [[p0, t1, c1], [c1, t2, c2], [c1, t3, c2], [c2, t4, p5]].each do |from, point, to|
        assert_operator distance(from, point) + distance(point, to), :<=, distance(from, to) + 0.01,
                        "#{data}: a turn reaches past the run it eases"
      end

      # And the two turns on the run between the corners do not meet.
      assert_operator distance(c1, t2) + distance(t3, c2), :<=, distance(c1, c2) + 0.01,
                      "#{data}: the two turns take more of the run between them than it has"
    end
  end

  # The clamp, asked directly. At the radius a figure actually uses it never
  # binds — every run of a movement path is at least twice it — so nothing above
  # exercises it, and defensive arithmetic nothing exercises is arithmetic
  # nobody knows the shape of. Handed a radius larger than the runs, it has to
  # keep every turn inside the run it eases.
  def test_the_clamp_holds_a_turn_inside_its_run
    graph = RSyntaxTree::SVGGraph.allocate
    square = [[0.0, 0.0], [0.0, 10.0], [40.0, 10.0], [40.0, 0.0]]
    d = graph.send(:rounded_polyline_d, square, 1000.0)
    points = coordinates(d)
    _p0, t1, c1, t2, t3, c2, t4, p5 = points

    [[square[0], t1, c1], [c1, t2, c2], [c1, t3, c2], [c2, t4, square[3]]].each do |from, point, to|
      assert_operator distance(from, point) + distance(point, to), :<=, distance(from, to) + 0.01,
                      "a turn reaches past the run it eases"
    end
    assert_equal square[3], p5, "the stroke still ends where it was told to"
    # The short runs are 10 long, so each turn takes at most 5 of them.
    assert_in_delta 5.0, distance(square[0], t1), 0.01
  end

  # A round cap is half the stroke's width of ink past the point the stroke ends
  # at, and an arrowhead has its tip at exactly that point — so the line came
  # through the tip. Measured on the pixel above the tip, that was 13% ink at
  # the head of a path and 81% at its tail, where the marker's apex sits on the
  # anchor rather than behind it.
  def test_a_path_with_an_arrowhead_is_squared_off
    arrowed = svg("[S [NP a+1] [VP [V b] [NP c+>1]]]")
    stroke = arrowed[%r{<path d='M[^']+'[^>]*marker-end[^>]*/>}]
    assert_includes stroke, "stroke-linecap:butt", "a stroke that ends in an arrowhead stops there"
  end

  # And only there. A path with no head is the dashed one, and every dash of it
  # wants its round ends.
  def test_a_dashed_path_keeps_its_round_ends
    dashed = svg("[S [NP a+1] [VP [V b] [NP c+1]]]")
    stroke = dashed[%r{<path d='M[^']+'[^>]*stroke-dasharray[^>]*/>}]
    assert_includes stroke, "stroke-linecap:round"
  end
end
