# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class MirrorTest < Minitest::Test
  DATA = "[S [NP [Det the] [N cat]] [VP [V sat] [PP [P on] [NP [Det the] [N mat]]]]]"
  SHADED_DATA = "[TP [DP everyone] [%@lightblue:T' [T will] [VP [V praise] [DP his_i_ friend]]]]"

  def build_svg(data, extra = {})
    opts = DEFAULT_OPTS.dup
    opts[:data] = data
    extra.each { |k, v| opts[k] = v }
    RSyntaxTree::RSGenerator.new(opts).draw_svg
  end

  # All tspans in document order: [{x:, y:, text:}, ...]
  def tspans(svg)
    svg.scan(%r{<tspan x='(-?[\d.]+)' y='(-?[\d.]+)'[^>]*>(.*?)</tspan>}m).map do |x, y, text|
      { x: x.to_f, y: y.to_f, text: text }
    end
  end

  def svg_width(svg)
    svg.match(/<svg width="([\d.]+)"/)[1].to_f
  end

  # 1. mirror: on flips the horizontal order of the leaves
  def test_mirror_reverses_leaf_order
    off = tspans(build_svg(DATA))
    on = tspans(build_svg(DATA, mirror: "on"))

    off_x = %w[cat sat mat].map { |w| off.find { |t| t[:text] == w }&.fetch(:x) }
    on_x = %w[cat sat mat].map { |w| on.find { |t| t[:text] == w }&.fetch(:x) }
    assert off_x.all?, "fixture words must be present (off)"
    assert on_x.all?, "fixture words must be present (on)"
    assert off_x[0] < off_x[1] && off_x[1] < off_x[2], "off: cat < sat < mat (left to right)"
    assert on_x[0] > on_x[1] && on_x[1] > on_x[2], "on: cat > sat > mat (right to left)"
  end

  # 2. mirror: on preserves the total image width
  def test_mirror_preserves_total_width
    off_w = svg_width(build_svg(DATA))
    on_w = svg_width(build_svg(DATA, mirror: "on"))
    assert_in_delta off_w, on_w, 2.0
  end

  # 3. mirror: on + region shade: the shade rect still covers the subtree
  def test_mirror_region_shade_contains_subtree
    svg = build_svg(SHADED_DATA, mirror: "on", fontstyle: "serif")
    shade = svg.scan(/<rect [^>]*>/).map do |tag|
      { x: tag[/x='(-?[\d.]+)'/, 1].to_f,
        w: tag[/width='(-?[\d.]+)'/, 1].to_f,
        opacity: tag[/fill-opacity='([\d.]+)'/, 1]&.to_f }
    end.find { |r| r[:opacity] && (r[:opacity] - 0.2).abs < 0.001 }
    refute_nil shade, "region shade rect should exist"

    ts = tspans(svg)
    %w[will praise].each do |w|
      t = ts.find { |s| s[:text] == w }
      refute_nil t, "#{w} tspan should exist"
      assert t[:x] >= shade[:x] && t[:x] <= shade[:x] + shade[:w],
             "#{w} (x=#{t[:x].round(1)}) should be inside shade x-range #{shade[:x].round(1)}..#{(shade[:x] + shade[:w]).round(1)}"
    end
  end

  # 4. ltr + mirror: no crash, and the root moves to the right edge
  def test_ltr_mirror_places_root_at_right
    plain = tspans(build_svg(DATA, direction: "ltr"))
    mirrored = tspans(build_svg(DATA, direction: "ltr", mirror: "on"))

    plain_root = plain.find { |t| t[:text] == "S" }
    plain_leaves = %w[cat sat mat].map { |w| plain.find { |t| t[:text] == w } }
    assert plain_leaves.all? { |leaf| plain_root[:x] < leaf[:x] }, "ltr: root is left of the leaves"

    root = mirrored.find { |t| t[:text] == "S" }
    leaves = %w[cat sat mat].map { |w| mirrored.find { |t| t[:text] == w } }
    assert leaves.all?, "fixture words must be present (ltr + mirror)"
    assert leaves.all? { |leaf| root[:x] > leaf[:x] }, "ltr + mirror: root is right of the leaves"
  end
end
