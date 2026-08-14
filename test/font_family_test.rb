# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

# Font resolution goes through fontconfig, so what the gem controls is the
# family fallback chain. These tests guard the chain itself: every style must
# be able to reach a family with full CJK coverage (Han + Hangul + kana),
# because the standalone Noto Sans/Serif JP faces carry no Hangul and only
# part of the simplified Han set.
class FontFamilyTest < Minitest::Test
  CJK_COVERING = /Noto (Sans|Serif|Sans Mono) CJK/.freeze

  def test_every_style_can_reach_full_cjk_coverage
    %i[sans serif mono cjk].each do |style|
      families = FontFamily.list(style)
      assert families.any? { |f| CJK_COVERING.match?(f) },
             "#{style}: no full-coverage CJK family in #{families.inspect}"
    end
  end

  def test_cjk_style_puts_the_cjk_family_first
    assert_match CJK_COVERING, FontFamily.list(:cjk).first
  end

  def test_styles_end_with_a_generic_family
    {
      sans: "sans-serif", serif: "serif", mono: "monospace", cjk: "sans-serif"
    }.each do |style, generic|
      assert_equal generic, FontFamily.list(style).last, "#{style} must end with #{generic}"
    end
  end

  def test_for_svg_quotes_multiword_families
    svg = FontFamily.for_svg(:sans)
    assert_includes svg, "'Noto Sans CJK JP'"
    refute_includes svg, "'sans-serif'"
  end

  def test_cjk_text_renders_without_raising_in_every_style
    data = "[S [NP 二つ] [VP [V 兩個] [N 두가지]]]"
    %w[sans serif mono cjk].each do |style|
      opts = DEFAULT_OPTS.dup
      opts[:data] = data
      opts[:fontstyle] = style
      svg = RSyntaxTree::RSGenerator.new(opts).draw_svg
      assert svg.include?("<svg"), "#{style}: no SVG produced"
    end
  end
end
