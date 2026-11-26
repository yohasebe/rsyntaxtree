# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/rsyntaxtree"

# A row keeps its labels aligned at the top, so a tall label — a feature
# matrix, a two-line label — reaches far below the short ones beside it. The
# line from a short node down to its children must start at that node's own
# label, not at the depth the tall neighbour set for the row.
class RowHeightTest < Minitest::Test
  # Where +text+ is set in the drawing: the baseline of the line holding it.
  def baseline(svg, text)
    svg[/<tspan[^>]*y=['"]([\d.]+)['"][^>]*>#{Regexp.escape(text)}</, 1].to_f
  end

  # The y at which the connector leaving the label set in +text+ downward
  # begins, read off the drawing: the highest point of a stroke standing at
  # the label's x below its baseline, so the edge arriving from above is not
  # mistaken for the one leaving below.
  def connector_top_under(svg, json, parent_label, text)
    node = json["nodes"].find { |n| n.dig("label", "raw") == parent_label }
    pos = node["position"]
    cx = pos["x"] + (pos["content_width"] / 2.0)
    floor = baseline(svg, text)

    points = svg.scan(/<polyline[^>]*?points=['"]([^'"]*)['"][^>]*>/).flatten.flat_map do |coords|
      coords.scan(/-?\d+(?:\.\d+)?/).map(&:to_f).each_slice(2).to_a
    end
    lines = svg.scan(/<line[^>]*?x1=['"]([\d.]+)['"][^>]*?y1=['"]([\d.]+)['"][^>]*?x2=['"]([\d.]+)['"][^>]*?y2=['"]([\d.]+)['"]/)
               .flat_map { |x1, y1, x2, y2| [[x1.to_f, y1.to_f], [x2.to_f, y2.to_f]] }
    (points + lines).select { |x, y| (x - cx).abs < 1.0 && y > floor }.map { |_x, y| y }.min
  end

  def draw(data, **opts)
    [RSyntaxTree::RSGenerator.new(data: data, format: "svg", **opts).draw_svg,
     JSON.parse(RSyntaxTree::RSGenerator.new(data: data, format: "json", **opts).draw_json)]
  end

  # A two-line label and a one-line label share a row; each has a child. The
  # one-line node's downward connector starts just under its own text, above
  # the two-line node's last line.
  def test_a_short_node_connects_from_its_own_bottom_not_the_rows
    data = "[S [TALL\\nX [A a]] [SH [B b]]]"
    [{}, { vmargin: 0.4 }].each do |opts|
      svg, json = draw(data, **opts)
      short_top = connector_top_under(svg, json, "SH", "SH")

      assert_operator short_top, :<, baseline(svg, "X"),
                      "#{opts}: the short node's connector starts at the tall neighbour's depth"
      assert_operator short_top - baseline(svg, "SH"), :<, 20,
                      "#{opts}: the short node's connector should start just under its own text"
    end
  end

  # Same, with a feature matrix as the tall label and polyline connectors —
  # the shape ruby-spacy draws morphology in.
  def test_a_plain_node_beside_a_matrix_keeps_its_branch
    data = "[S [MAT [#(a\\tb\\nc\\td#) x]] [PLAIN [C c]]]"
    [{}, { vmargin: 0.4 }].each do |opts|
      svg, json = draw(data, polyline: "on", **opts)
      plain_top = connector_top_under(svg, json, "PLAIN", "PLAIN")

      assert_operator plain_top - baseline(svg, "PLAIN"), :<, 20,
                      "#{opts}: PLAIN's branch should descend from just under its own text"
    end
  end
end
