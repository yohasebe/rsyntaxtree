# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "nokogiri"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

# An empty-label node (`<>`) acts as a pass-through joint: connectors run
# continuously through it instead of leaving a gap at the invisible label.
class EmptyNodeTest < Minitest::Test
  def svg_lines(data, extra = {})
    opts = DEFAULT_OPTS.dup
    opts[:data] = data
    opts[:fontstyle] = "sans"
    extra.each { |k, v| opts[k] = v }
    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "SVG should be valid XML"
    # Connector lines carry x1/y1/x2/y2; sample-legend lines in defs use a
    # bare y attribute and must be ignored.
    doc.css("line").select { |l| l["y1"] }.map do |l|
      %w[x1 y1 x2 y2].map { |a| l[a].to_f }
    end
  end

  def test_connector_passes_through_empty_node
    lines = svg_lines("[the [<> ði]]")
    # The two segments (parent -> empty, empty -> leaf) must share an
    # endpoint at the empty node's center, leaving no gap.
    shared = lines.combination(2).any? do |(a, b)|
      ends_a = [[a[0], a[1]], [a[2], a[3]]]
      ends_b = [[b[0], b[1]], [b[2], b[3]]]
      ends_a.product(ends_b).any? do |(pa, pb)|
        (pa[0] - pb[0]).abs < 0.5 && (pa[1] - pb[1]).abs < 0.5
      end
    end
    assert shared, "segments around the empty node should share an endpoint"
  end

  def test_normal_connector_keeps_gap
    lines = svg_lines("[the [X ði]]")
    shared = lines.combination(2).any? do |(a, b)|
      ends_a = [[a[0], a[1]], [a[2], a[3]]]
      ends_b = [[b[0], b[1]], [b[2], b[3]]]
      ends_a.product(ends_b).any? do |(pa, pb)|
        (pa[0] - pb[0]).abs < 0.5 && (pa[1] - pb[1]).abs < 0.5
      end
    end
    refute shared, "segments around a labeled node must not touch"
  end

  def test_empty_node_ltr_valid
    lines = svg_lines("[the [<> ði]]", direction: "ltr")
    refute_empty lines
  end

  def test_empty_node_with_tidy
    lines = svg_lines("[S [the [<> ði]] [NP [N noun]]]", tidy: "medium")
    refute_empty lines
  end
end
