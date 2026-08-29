# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# vmargin gives a label the same clearance above and below, measured from the
# type itself. The classic spacing measures from the layout box instead, whose
# edges sit unevenly around the ink — which is why the air under a label never
# quite matched the air over it, and why unset has to mean the classic drawing
# to the byte: no one value of the symmetric geometry reproduces it.
class VmarginTest < Minitest::Test
  include RSyntaxTree

  def svg(data, opts = {})
    RSGenerator.new({ data: data, format: "svg", fontsize: "16" }.merge(opts)).draw_svg
  end

  H = 44.8 # the vertical rhythm at fontsize 16 (internally doubled, x 1.4)

  # The gap on each side of every plain connector, measured against each
  # label's own ink — which is what the row-union clearances resolve to when
  # every row holds one label, as in the trees these tests draw.
  def band_gaps(out)
    fam = FontFamily.for_pango(:sans)
    texts = out.scan(/<tspan[^>]*y='([\d.]+)'[^>]*>([^<]*)</)
               .map do |y, s|
                 m = FontMetrics.get_metrics(s, fam, 32, :normal, :normal)
                 { s: s, top: y.to_f - m.ink_above, bottom: y.to_f + (m.ink_height - m.ink_above) }
               end
    lines = out.scan(/<line[^>]*y1='([\d.]+)' x2=[^>]*y2='([\d.]+)'/)
               .map { |a, b| [a.to_f, b.to_f].sort }
    lines.map do |top_end, bottom_end|
      above = texts.select { |t| t[:bottom] <= top_end + 1 }.map { |t| top_end - t[:bottom] }.min
      below = texts.select { |t| t[:top] >= bottom_end - 1 }.map { |t| t[:top] - bottom_end }.min
      [above, below]
    end
  end

  def test_the_default_is_the_symmetric_geometry_at_its_own_value
    assert_equal svg("[S [NP a] [VP [V b] [NP c]]]"),
                 svg("[S [NP a] [VP [V b] [NP c]]]", vmargin: "0.4"),
                 "unset must mean vmargin 0.4, nothing else"
    band_gaps(svg("[S [NP a]]")).each do |above, below|
      assert_in_delta above, below, 0.6, "the default draws unequal air"
    end
  end

  def test_the_clearances_match_the_band_on_both_sides
    [0.2, 0.35, 0.5].each do |v|
      out = svg("[S [NP a]]", vmargin: v.to_s)
      band_gaps(out).each do |above, below|
        assert_in_delta v * H, above, 0.6, "vmargin #{v}: gap above the line"
        assert_in_delta v * H, below, 0.6, "vmargin #{v}: gap below the line"
      end
    end
  end

  # An enclosure is a drawn shape, so its clearance is measured from its own
  # edge — the classic drawing already kept those symmetric, and vmargin takes
  # the same edge and applies its own m.
  def test_an_enclosure_keeps_its_clearance_from_the_drawn_edge
    out = svg("[##A [##B c]]", vmargin: "0.35")
    rects = out.scan(/<polygon[^>]*points='([^']+)'/).flatten
                .map { |pts| pts.scan(/[-\d.]+/).map(&:to_f).each_slice(2).map(&:last).minmax }
    line = out.scan(/<line[^>]*y1='([\d.]+)' x2=[^>]*y2='([\d.]+)'/)
              .map { |a, b| [a.to_f, b.to_f].sort }.first
    gap_above = line[0] - rects[0][1]
    gap_below = rects[1][0] - line[1]
    assert_in_delta 0.35 * H, gap_above, 0.6
    assert_in_delta 0.35 * H, gap_below, 0.6
  end

  def test_a_triangle_keeps_the_same_clearances
    out = svg("[N ^two<>words]", vmargin: "0.35")
    tri = out[/<polygon[^>]*points='([^']+)'/, 1]
    ys = tri.scan(/[-\d.]+ [-\d.]+/).map { |p| p.split.last.to_f }
    apex = ys.min
    base = ys.max
    fam = FontFamily.for_pango(:sans)
    # A leaf of several words is one <text> holding several tspans — the
    # visible words, and an invisible one for each space — so the ink the
    # library measured is the whole line's. The check reassembles the line.
    rows = out.scan(%r{<text[^>]*>(.*?)</text>}m).map do |(block)|
      y = block[/y='([\d.]+)'/, 1].to_f
      [y, block.scan(/>([^<]+)</).join.gsub(WHITESPACE_BLOCK, " ")]
    end
    p_y, p_s = rows.min_by(&:first)
    l_y, l_s = rows.max_by(&:first)
    p_m = FontMetrics.get_metrics(p_s, fam, 32, :normal, :normal)
    l_m = FontMetrics.get_metrics(l_s, fam, 32, :normal, :normal)
    parent_bottom = p_y + (p_m.ink_height - p_m.ink_above)
    leaf_top = l_y - l_m.ink_above
    assert_in_delta 0.35 * H, apex - parent_bottom, 0.6, "apex below the node"
    assert_in_delta 0.35 * H, leaf_top - base, 0.6, "base above the leaf"
  end

  def test_the_pitch_follows_the_margin
    tall = svg("[S [NP a]]", vmargin: "0.5")[/height="([\d.]+)"/, 1].to_f
    tight = svg("[S [NP a]]", vmargin: "0.2")[/height="([\d.]+)"/, 1].to_f
    assert_operator tight, :<, tall
  end

  def test_nonsense_and_range_are_refused
    e = assert_raises(RSTError) { svg("[S a]", vmargin: "abc") }
    assert_equal :invalid_option, e.code
    e = assert_raises(RSTError) { svg("[S a]", vmargin: "1.5") }
    assert_equal :invalid_option, e.code
    assert_equal svg("[S [NP a]]"), svg("[S [NP a]]", vmargin: ""),
                 "an empty string is an option not given (and so the default 0.4)"
  end

  def test_lsif_records_the_value_and_the_default
    require "json"
    with = JSON.parse(RSGenerator.new(data: "[S a]", format: "lsif", vmargin: "0.35").draw_lsif)
    without = JSON.parse(RSGenerator.new(data: "[S a]", format: "lsif").draw_lsif)
    assert_equal 0.35, with.dig("meta", "source", "params", "vmargin")
    assert_equal 0.4, without.dig("meta", "source", "params", "vmargin")
  end
end
