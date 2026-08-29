# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# Shear tilts the finished figure: the layout is computed as ever, and the
# drawn picture — plane, shades, tree, rails — is carried through one affine
# map. An affine map preserves incidence, so nothing can newly touch or cross;
# what there is to test is that the map is the one asked for, that the canvas
# follows the tilted corners, and that the plane behind the figure encloses
# every piece of ink laid on it.
class ShearTest < Minitest::Test
  include RSyntaxTree

  TREE = "[S [NP [D the] [N man]] [VP [V put] [NP [D the] [N book]]]]"

  def svg(data = TREE, opts = {})
    RSGenerator.new({ data: data, format: "svg" }.merge(opts)).draw_svg
  end

  # --- the option is an option ------------------------------------------

  def test_no_shear_is_byte_identical_to_before_the_option_existed
    assert_equal svg, svg(TREE, shear: "0"),
                 "shear 0 must not change one byte of the output"
  end

  def test_the_angle_becomes_the_advertised_matrix
    out = svg(TREE, shear: "20")
    # Positive degrees lean the top right; y grows downward, so k is -tan 20.
    assert_includes out, "matrix(1,0,-0.364,1,0,0)"
  end

  def test_nonsense_is_refused_rather_than_read_as_zero
    # A non-numeric string reads as 0.0, and 0 sits inside shear's range —
    # the one range here that contains it — so without its own check "abc"
    # would quietly mean "no shear".
    e = assert_raises(RSTError) { svg(TREE, shear: "abc") }
    assert_equal :invalid_option, e.code
    e = assert_raises(RSTError) { svg(TREE, shear: "20deg") }
    assert_equal :invalid_option, e.code
  end

  def test_the_blank_and_the_range_behave_like_every_numeric_option
    assert_equal svg, svg(TREE, shear: ""), "an empty string is an option not given"
    e = assert_raises(RSTError) { svg(TREE, shear: "60") }
    assert_equal :invalid_option, e.code
  end

  # --- the canvas follows the tilt --------------------------------------

  # Every coordinate the group draws, pushed through the shear, has to land
  # inside the viewBox. This check folds the transform in by hand because a
  # reader of the raw attributes sees pre-shear numbers against a post-shear
  # canvas.
  def test_every_sheared_coordinate_lands_on_the_canvas
    ["20", "-20", "45"].each do |deg|
      out = svg("[S [NP+>1 [N who]] [VP [V saw] [NP [N *t*+1]]]]", shear: deg)
      k = out[/matrix\(1,0,([-\d.]+),1/, 1].to_f
      vb = out.match(/viewBox="([-\d.e]+), ([-\d.e]+), ([\d.e]+), ([\d.e]+)"/)
      x0 = vb[1].to_f
      x1 = x0 + vb[3].to_f
      body = out[/<g transform[^>]*>(.*)<\/g>/m, 1]
      xs = []
      body.scan(/(?:x1|x2|x)=['"]([-\d.e]+)['"]/) { xs << $1.to_f }
      body.scan(/(?:y1|y2|y)=['"]([-\d.e]+)['"]/) { }
      pairs = []
      body.scan(/(?:x1|x)=['"]([-\d.e]+)['"]\s+(?:y1|y)=['"]([-\d.e]+)['"]/) { pairs << [$1.to_f, $2.to_f] }
      body.scan(/ d=['"]([^'"]+)['"]/).flatten.each do |d|
        d.scan(/(-?\d+(?:\.\d+)?(?:e-?\d+)?),(-?\d+(?:\.\d+)?(?:e-?\d+)?)/) { pairs << [$1.to_f, $2.to_f] }
      end
      refute_empty pairs, "#{deg}: nothing to check"
      pairs.each do |x, y|
        sx = x + k * y
        assert_operator sx, :>=, x0 - 0.5, "#{deg}: ink left of the canvas"
        assert_operator sx, :<=, x1 + 0.5, "#{deg}: ink right of the canvas"
      end
    end
  end

  # --- the plane --------------------------------------------------------

  def plane_rect(out)
    m = out.match(/<g transform[^>]*>\n<rect x="([-\d.]+)" y="([-\d.]+)" width="([\d.]+)" height="([\d.]+)"/)
    m && { x: m[1].to_f, y: m[2].to_f, w: m[3].to_f, h: m[4].to_f }
  end

  def test_the_plane_is_there_by_default_and_leaves_when_told
    assert plane_rect(svg(TREE, shear: "20")), "no plane behind the sheared figure"
    refute plane_rect(svg(TREE, shear: "20", shear_plane: "off")), "the plane stayed after off"
    refute_includes svg(TREE), "fill-opacity=\"0.12\"", "a plane with no shear"
  end

  # A clear background is asked for in order to lay the figure over something
  # else, and an opaque sheet under the figure is the one thing that would
  # defeat that. The plane goes when the background does.
  def test_a_clear_background_takes_the_plane_with_it
    refute plane_rect(svg(TREE, shear: "20", transparent: "on")),
           "the plane stayed on a transparent background"
    assert plane_rect(svg(TREE, shear: "20", transparent: "off"))
  end

  # Fill alone. A region shade is bounded because it marks one part of a
  # figure off from the rest; the plane is under all of it, and an edge round
  # the whole drawing reads as a frame.
  def test_the_plane_has_no_outline
    out = svg(TREE, shear: "20")
    plane = out[/<rect x="[-\d.]+" y="[-\d.]+"[^>]*fill-opacity="0.12"[^>]*\/>/]
    refute_nil plane
    assert_includes plane, 'stroke="none"'
  end

  def test_the_plane_takes_a_colour_and_refuses_a_non_colour
    assert_includes svg(TREE, shear: "20", shear_plane: "lightblue"), "fill=\"lightblue\""
    assert_includes svg(TREE, shear: "20", shear_plane: "#8e4585"), "fill=\"#8e4585\""
    e = assert_raises(RSTError) { svg(TREE, shear: "20", shear_plane: "plaid") }
    assert_equal :invalid_option, e.code
    e = assert_raises(RSTError) { svg(TREE, shear: "20", shear_plane: "#zzz") }
    assert_equal :invalid_option, e.code
  end

  # The plane and the figure share the group, so both live in pre-shear
  # coordinates: the rail of a movement path has to sit inside the plane with
  # clear room, or the tilt would carry the rail through its edge.
  def test_the_plane_encloses_a_movement_rail
    out = svg("[S [NP+>1 [N who]] [VP [V saw] [NP [N *t*+1]]]]", shear: "20")
    plane = plane_rect(out)
    rails = out.scan(/ d=['"]([^'"]+)['"]/).flatten.select { |d| d.count("L") >= 2 }
    refute_empty rails
    rails.each do |d|
      d.scan(/(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/) do
        x = $1.to_f
        y = $2.to_f
        assert x > plane[:x] && x < plane[:x] + plane[:w] &&
               y > plane[:y] && y < plane[:y] + plane[:h],
               "rail point #{x},#{y} outside the plane"
      end
    end
  end

  # --- the other formats ------------------------------------------------

  def test_tikz_refuses_a_sheared_figure_by_name
    e = assert_raises(RSTError) do
      RSGenerator.new(data: TREE, format: "tikz", shear: "20").draw_tikz
    end
    assert_equal :invalid_option, e.code
    assert_match(/shear/i, e.message + e.hint.to_s)
    RSGenerator.new(data: TREE, format: "tikz").draw_tikz # 0 stays fine
  end

  def test_json_records_the_angle
    require "json"
    data = JSON.parse(RSGenerator.new(data: TREE, format: "json", shear: "20").draw_json)
    assert_equal 20.0, data.dig("meta", "source", "params", "shear")
  end

  def test_png_of_a_sheared_figure_renders
    png = RSGenerator.new(data: TREE, format: "png", shear: "20").draw_png
    assert_equal "\x89PNG".b, png[0, 4].b
  end
end
