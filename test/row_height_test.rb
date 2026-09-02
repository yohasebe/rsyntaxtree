# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/rsyntaxtree"

# A row keeps its labels aligned at the top, so a tall label — a feature
# matrix, a two-line label — reaches far below the short ones beside it. The
# line from a short node down to its children must start at that node's own
# label, not at the depth the tall neighbour set for the row.
class RowHeightTest < Minitest::Test
  # The y at which the connector leaving +parent_label+ downward begins,
  # read off the drawing: the highest point of the vertical stroke standing
  # at the parent's own x.
  def connector_top_under(data, parent_label, **opts)
    svg = RSyntaxTree::RSGenerator.new(data: data, format: "svg", **opts).draw_svg
    j = JSON.parse(RSyntaxTree::RSGenerator.new(data: data, format: "json", **opts).draw_json)
    node = j["nodes"].find { |n| n.dig("label", "raw") == parent_label }
    pos = node["position"]
    cx = pos["x"] + pos["content_width"] / 2.0
    # Below the label, so the edge arriving from above is not mistaken for
    # the one leaving below.
    floor = pos["y"] + pos["content_height"] / 2.0

    points = svg.scan(/<polyline[^>]*?points=['"]([^'"]*)['"][^>]*>/).flatten.flat_map do |coords|
      coords.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
    end
    lines = svg.scan(/<line[^>]*?x1=['"]([\d.]+)['"][^>]*?y1=['"]([\d.]+)['"][^>]*?x2=['"]([\d.]+)['"][^>]*?y2=['"]([\d.]+)['"]/)
               .flat_map { |x1, y1, x2, y2| [[x1.to_f, y1.to_f], [x2.to_f, y2.to_f]] }
    ys = (points + lines).select { |x, y| (x - cx).abs < 1.0 && y > floor }.map { |_x, y| y }
    ys.min
  end

  def box_bottom(data, label, **opts)
    j = JSON.parse(RSyntaxTree::RSGenerator.new(data: data, format: "json", **opts).draw_json)
    n = j["nodes"].find { |x| x.dig("label", "raw") == label }
    n["position"]["y"] + n["position"]["content_height"]
  end

  # A two-line label and a one-line label share a row; each has a child. The
  # one-line node's downward connector starts near its own bottom, well above
  # where the two-line node's bottom would put it.
  def test_a_short_node_connects_from_its_own_bottom_not_the_rows
    data = "[S [TALL\\nX [A a]] [SH [B b]]]"
    tall_label = "TALL\\nX"
    short_top = connector_top_under(data, "SH")
    short_bottom = box_bottom(data, "SH")
    tall_bottom = box_bottom(data, tall_label)

    assert short_top < tall_bottom - 20,
           "the short node's connector starts at the tall neighbour's depth (#{short_top} vs tall #{tall_bottom})"
    assert_in_delta short_bottom, short_top, 20,
           "the short node's connector should start near its own bottom (#{short_bottom}), got #{short_top}"
  end

  # Same, with a feature matrix as the tall label and polyline connectors —
  # the shape ruby-spacy draws morphology in.
  def test_a_plain_node_beside_a_matrix_keeps_its_branch
    data = "[S [MAT [#(a\\tb\\nc\\td#) x]] [PLAIN [C c]]]"
    plain_top = connector_top_under(data, "PLAIN", polyline: "on")
    plain_bottom = box_bottom(data, "PLAIN", polyline: "on")
    assert_in_delta plain_bottom, plain_top, 20,
           "PLAIN's branch should descend from its own bottom (#{plain_bottom}), got #{plain_top}"
  end
end
