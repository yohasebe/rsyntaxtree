# frozen_string_literal: true

require "minitest/autorun"
require "pango"
require_relative "../lib/rsyntaxtree"

# Guards the font family chains against the failure that shipped in 1.8.0:
# scripts left to the generic fallback resolved to a different font on every
# machine, and on Alpine the Arabic block was claimed by Noto Sans Math, which
# has the glyphs but no joining rules. Naming the families is only worth
# anything if they actually win, so assert the resolution Pango performs.
#
# The assertions need the fonts installed, so each one skips when the expected
# family is absent. In the project's Docker image they all run.
class FontResolutionTest < Minitest::Test
  SAMPLES = [
    { script: "Arabic", text: "الطالب", sans: "Noto Sans Arabic", serif: "Noto Naskh Arabic" },
    { script: "Hebrew", text: "שלום", sans: "Noto Sans Hebrew", serif: "Noto Serif Hebrew" },
    { script: "Devanagari", text: "नमस्ते", sans: "Noto Sans Devanagari", serif: "Noto Serif Devanagari" },
    { script: "Thai", text: "สวัสดี", sans: "Noto Sans Thai", serif: "Noto Serif Thai" },
    { script: "Khmer", text: "សួស្ដី", sans: "Noto Sans Khmer", serif: "Noto Serif Khmer" }
  ].freeze

  def setup
    surface = Cairo::ImageSurface.new(:argb32, 10, 10)
    @context = Cairo::Context.new(surface)
  end

  def resolved_families(text, style, cjk_priority: false)
    layout = @context.create_pango_layout
    layout.font_description = Pango::FontDescription.new("#{FontFamily.for_pango(style, cjk_priority: cjk_priority)} 20")
    layout.text = text
    families = []
    iter = layout.iter
    loop do
      run = iter.run
      families << run.item.analysis.font.describe.family if run
      break unless iter.next_run
    end
    [families.uniq, layout.unknown_glyphs_count]
  end

  def installed?(family)
    @installed ||= `fc-list : family 2>/dev/null`.split(/[,\n]/).map(&:strip).to_set
    @installed.include?(family)
  end

  SAMPLES.each do |sample|
    define_method("test_#{sample[:script].downcase}_resolves_to_its_noto_family") do
      skip "#{sample[:sans]} not installed" unless installed?(sample[:sans])

      families, unknown = resolved_families(sample[:text], :sans)
      assert_equal 0, unknown, "#{sample[:script]} produced tofu"
      assert_includes families, sample[:sans]
    end

    define_method("test_#{sample[:script].downcase}_survives_cjk_priority") do
      skip "#{sample[:sans]} not installed" unless installed?(sample[:sans])

      # A label containing any non-ASCII character sets contains_cjk?, which
      # swaps the first two families. The swap must not change which font wins
      # for these scripts.
      families, unknown = resolved_families(sample[:text], :sans, cjk_priority: true)
      assert_equal 0, unknown, "#{sample[:script]} produced tofu under cjk_priority"
      assert_includes families, sample[:sans]
    end

    define_method("test_#{sample[:script].downcase}_resolves_in_serif") do
      skip "#{sample[:serif]} not installed" unless installed?(sample[:serif])

      families, unknown = resolved_families(sample[:text], :serif)
      assert_equal 0, unknown, "#{sample[:script]} produced tofu in serif"
      assert_includes families, sample[:serif]
    end
  end

  def test_mathematical_alphanumerics_still_resolve
    # Example 008 labels its little v with U+1D463. Removing Arabic from Noto
    # Sans Math must not take these with it.
    _, unknown = resolved_families("\u{1D463}P", :sans)
    assert_equal 0, unknown, "mathematical italic small v produced tofu"
  end

  def test_emoji_resolve_to_an_outline_font
    skip "Noto Emoji not installed" unless installed?("Noto Emoji") || installed?("OpenMoji Black")

    families, unknown = resolved_families("😀", :sans)
    assert_equal 0, unknown, "emoji produced tofu"
    # Colour emoji are measured but not rendered by librsvg in this pipeline.
    # Only the fontconfig side is asserted: on macOS Pango resolves through
    # CoreText, which returns Apple Color Emoji for every emoji codepoint no
    # matter what the chain asks for, and nothing in the gem can change that.
    refute_includes families, "Noto Color Emoji"
  end
end
