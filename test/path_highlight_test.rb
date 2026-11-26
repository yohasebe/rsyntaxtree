# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/rsyntaxtree"

# A path through the tree: `+=N` on two labels draws every edge between them,
# up to the node where they meet and down again, heavier and in the scheme's
# emphasis colour.
class PathHighlightTest < Minitest::Test
  TREE = "[S [NP [D the] [N cat+=1]] [VP [V saw] [NP [D a] [N dog+=1]]]]"

  def json(data, **opts)
    JSON.parse(RSyntaxTree::RSGenerator.new(data: data, format: "json", **opts).draw_json)
  end

  # The edges on the path, as the labels at their two ends.
  def path_edges(data, **opts)
    doc = json(data, **opts)
    label = doc["nodes"].to_h { |n| [n["id"], n.dig("label", "raw")] }
    doc["edges"].select { |e| e["on_path"] }.map { |e| [label[e["from"]], label[e["to"]]] }
  end

  def test_the_path_runs_up_to_where_the_ends_meet_and_down_again
    assert_equal [%w[S NP], %w[NP N], %w[N cat], %w[S VP], %w[VP NP], %w[NP N], %w[N dog]].sort,
                 path_edges(TREE).sort
  end

  def test_an_end_on_a_node_stops_the_path_there
    assert_equal [%w[S NP], %w[S VP]].sort, path_edges("[S [NP+=1 [D the] [N cat]] [VP+=1 [V ran]]]").sort
  end

  def test_one_end_above_the_other
    assert_equal [%w[S VP], %w[VP V]].sort, path_edges("[S+=1 [NP a] [VP [V+=1 b]]]").sort
  end

  def test_the_markers_are_not_drawn
    svg = RSyntaxTree::RSGenerator.new(data: TREE, format: "svg").draw_svg

    refute_includes svg, "+="
  end

  # Heavier than the other edges, and in the colour bold text takes.
  def test_path_edges_are_heavier_and_in_the_emphasis_colour
    { "modern" => "#D55E00", "traditional" => "red" }.each do |scheme, colour|
      svg = RSyntaxTree::RSGenerator.new(data: TREE, format: "svg", color: scheme).draw_svg
      lines = svg.scan(/<line style='([^']*)'/).flatten
      widths = lines.map { |l| l[/stroke-width:([\d.]+)/, 1].to_f }

      assert_equal 7, lines.count { |l| l.include?("stroke:#{colour};") }, scheme
      assert_operator widths.max, :>, widths.min * 2, scheme
    end
  end

  # Without colour the weight alone marks the path.
  def test_without_colour_the_weight_marks_the_path
    svg = RSyntaxTree::RSGenerator.new(data: TREE, format: "svg", color: "none").draw_svg
    lines = svg.scan(/<line style='([^']*)'/).flatten
    heavy = lines.map { |l| l[/stroke-width:([\d.]+)/, 1].to_f }.tally

    assert_equal [6, 7], heavy.values.sort
    assert(lines.all? { |l| l.include?("stroke:black;") })
  end

  def test_a_triangle_on_the_path_is_drawn_heavier
    svg = RSyntaxTree::RSGenerator.new(data: "[S [NP the cat+=1] [VP ran+=1]]", format: "svg").draw_svg
    polygon = svg[/<polygon style='[^']*'/]

    assert_includes polygon, "#D55E00"
  end

  def test_tikz_draws_the_path_heavier
    tikz = RSyntaxTree::RSGenerator.new(data: TREE, format: "tikz").draw_tikz

    assert_equal 7, tikz.scan("edge+={line width=").size
  end

  def test_every_direction_draws_the_path
    %w[ttb btt ltr].each do |direction|
      assert_equal 7, path_edges(TREE, direction: direction).size, direction
    end
  end

  def error(data, **opts)
    RSyntaxTree::RSGenerator.new(data: data, format: "svg", **opts).draw_svg
    nil
  rescue RSTError => e
    e
  end

  def test_a_path_takes_exactly_two_ends
    assert_equal :path_ends, error("[S [NP a+=1] [VP b]]").code
    assert_equal :path_ends, error("[S [NP a+=1] [VP b+=1] [C c+=1]]").code
  end

  def test_only_one_path_is_drawn
    assert_equal :path_numbers, error("[S [NP a+=1] [VP b+=1] [C c+=2] [D d+=2]]").code
  end

  def test_a_derivation_refuses_a_path
    assert_equal :invalid_option, error(TREE, derivation: "on").code
  end

  def test_an_unfinished_marker_is_named
    e = error("[S [NP a+=] [VP b]]")

    assert_equal :incomplete_marker, e.code
    assert_includes e.hint, "+=1"
  end

  # A movement path and a highlighted path can end on the same label.
  def test_a_path_and_a_movement_path_share_a_label
    svg = RSyntaxTree::RSGenerator.new(data: "[S [NP what+1+=1] [VP [V saw] [NP t+1+=1]]]", format: "svg").draw_svg

    assert_includes svg, "#CC79A7"
    assert_includes svg, "#D55E00"
  end

  # A rule name is drawn as written, whatever it ends in; the markers are
  # read from the label it belongs to.
  def test_a_rule_name_is_not_read_for_markers
    svg = RSyntaxTree::RSGenerator.new(data: "[S\\tR+=1 [A a]]", format: "svg", derivation: "on").draw_svg

    assert_includes svg, "R+=1"
    assert_equal :invalid_option, error("[S+=1\\tR [A+=1\\tQ a]]", derivation: "on").code
  end

  def test_a_line_break_after_the_marker_keeps_it
    assert_equal 4, path_edges("[S [A a+=1\\n] [B b+=1\\n]]").size
  end

  def test_hidden_connectors_stay_hidden_on_the_path
    svg = RSyntaxTree::RSGenerator.new(data: "[S [A a+=1] [B b+=1]]", format: "svg", hide_default_connectors: "on").draw_svg

    assert(svg.scan(/<line style='([^']*)'/).flatten.all? { |l| l.include?("stroke:none;") })
  end

  # TikZ draws every edge, whatever hides one in the SVG, and every one on
  # the path heavier.
  def test_tikz_draws_every_edge_on_the_path_heavier
    [{ leafstyle: "nothing" }, { hide_default_connectors: "on" }].each do |opts|
      tikz = RSyntaxTree::RSGenerator.new(data: "[S [A a+=1] [B b+=1]]", format: "tikz", **opts).draw_tikz

      assert_equal 4, tikz.scan("edge+={line width=").size, opts.inspect
    end
  end

  # Every output refuses a link with the wrong number of ends.
  def test_json_refuses_what_svg_refuses
    ["[S [A a+-1] [B b]]", "[S [A a+1] [B b]]", "[S [A a+1] [B b+1] [C c+1]]"].each do |data|
      codes = %w[svg json].map do |format|
        RSyntaxTree::RSGenerator.new(data: data, format: format).send("draw_#{format}")
        nil
      rescue RSTError => e
        e.code
      end

      refute_nil codes.first, data
      assert_equal codes.first, codes.last, data
    end
  end

  # Two markers on one node are one end, joined to nothing, in every format.
  def test_two_markers_on_one_node_are_one_end
    ["[S [A a+1+1] [B b]]", "[S [A a+-1+-1] [B b]]"].each do |data|
      %w[svg json tikz].each do |format|
        assert_raises(RSTError, "#{data} #{format}") do
          RSyntaxTree::RSGenerator.new(data: data, format: format).send("draw_#{format}")
        end
      end
    end
  end

  def test_an_escaped_caret_stays_in_the_label
    raw = json("[S [A a\\^+=1] [B b+=1]]")["nodes"].map { |n| n.dig("label", "raw") }

    assert_includes raw, "a\\^"
  end
end
