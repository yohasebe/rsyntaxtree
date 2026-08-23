# frozen_string_literal: true

#==========================
# utils.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require 'pango'

# Font family lists shared by the SVG output and the Pango-based text
# measurement. Each entry is an ordered list of family names; the FontFamily
# helpers format it for SVG (quoted) or for Pango::FontDescription#family
# (unquoted). Keeping a single source guarantees that measurement and
# rendering resolve through the same fallback chain.
#
# Scripts beyond Latin and CJK are named explicitly rather than left to the
# generic fallback, because the generic fallback is not the same font on every
# machine: on Alpine the Arabic block was picked up by Noto Sans Math, which
# has the glyphs but no joining rules and so rendered Arabic as isolated
# letters, while on Debian the same text fell to DejaVu Sans. A family is
# listed here when (i) the gallery has an example in that script, or (ii) a
# concrete environment-dependent failure has been reported for it. Anything
# else stays with the generic fallback — an unbounded list is unmaintainable.
SCRIPT_FAMILIES_SANS = ["Noto Sans Arabic", "Noto Sans Hebrew", "Noto Sans Devanagari", "Noto Sans Thai", "Noto Sans Khmer"].freeze
# Noto has no serif Arabic; Naskh is its serif-like counterpart, with Noto Sans
# Arabic behind it for systems that ship one but not the other.
SCRIPT_FAMILIES_SERIF = ["Noto Naskh Arabic", "Noto Sans Arabic", "Noto Serif Hebrew", "Noto Serif Devanagari", "Noto Serif Thai", "Noto Serif Khmer"].freeze

# Monochrome emoji faces only. Colour emoji fonts carry their glyphs as bitmap
# or COLR tables, which Pango happily measures but librsvg does not draw, so a
# colour font in this list would give a figure whose emoji are blank or blobbed.
#
# This holds only where Pango resolves through fontconfig. On macOS it goes
# through CoreText, which answers every emoji codepoint with Apple Color Emoji
# whatever the chain asks for; emoji figures have to be generated elsewhere.
EMOJI_FAMILIES = ["OpenMoji", "OpenMoji Color", "OpenMoji Black", "Noto Emoji"].freeze

# Mathematical alphanumerics (U+1D400–) label heads such as the little v of vP.
# Neither Noto Sans nor Noto Serif covers the block, so without these entries
# the glyphs came from whatever the machine happened to offer — Noto Sans Math
# on Alpine, DejaVu Serif on Debian/Ubuntu, STIX Two Math on macOS. Noto Sans
# Math is the only Noto face that covers the block and it is a sans design, so
# the serif style asks for a serif source first. Listed after the script
# families: Noto Sans Math also claims the Arabic block without joining rules,
# and must never be reached before Noto Sans Arabic.
MATH_FAMILIES_SANS = ["Noto Sans Math"].freeze
MATH_FAMILIES_SERIF = ["DejaVu Serif", "Noto Sans Math"].freeze

FONT_FAMILIES = {
  sans:  (["Noto Sans", "Noto Sans JP", "Noto Sans CJK JP"] + SCRIPT_FAMILIES_SANS + MATH_FAMILIES_SANS + EMOJI_FAMILIES + ["sans-serif"]).freeze,
  serif: (["Noto Serif", "Noto Serif JP", "Noto Serif CJK JP"] + SCRIPT_FAMILIES_SERIF + MATH_FAMILIES_SERIF + EMOJI_FAMILIES + ["serif"]).freeze,
  # Noto ships no monospaced faces for these scripts, so the mono style borrows
  # the proportional ones rather than dropping to the generic fallback.
  mono:  (["Noto Sans Mono", "Noto Sans JP", "Noto Sans Mono CJK JP"] + SCRIPT_FAMILIES_SANS + MATH_FAMILIES_SANS + EMOJI_FAMILIES + ["monospace"]).freeze,
  # The cjk style puts a full-coverage CJK family first, for text that mixes
  # Han, Hangul and kana. Latin falls back to the same Noto faces the sans
  # style uses. (Before 1.8.0 this was WQY Zen Hei.)
  cjk:   (["Noto Sans CJK JP", "Noto Sans", "Noto Sans JP"] + SCRIPT_FAMILIES_SANS + MATH_FAMILIES_SANS + EMOJI_FAMILIES + ["sans-serif"]).freeze
}.freeze

module FontFamily
  # One order, used by the measuring and by the drawing alike. There was a
  # second, with the CJK face moved to the front, which measurement switched to
  # as soon as any character outside ASCII appeared anywhere in the figure while
  # the drawing kept to this one — so Latin text was measured in a face it was
  # not set in. Fontconfig reaches the CJK faces through this order anyway, the
  # scripts that need them measuring the same either way, so the second order
  # bought nothing and is gone.
  def list(style)
    FONT_FAMILIES.fetch(style.to_sym)
  end

  def for_svg(style)
    list(style).map { |name| name.include?(" ") ? "'#{name}'" : name }.join(", ")
  end

  def for_pango(style)
    list(style).join(", ")
  end

  module_function :list, :for_svg, :for_pango
end

class String
  def contains_emoji?
    !!(gsub(WHITESPACE_BLOCK, "").gsub(/\d/, "") =~ /\p{Emoji}/)
  end

  def all_emoji?
    !!(gsub(WHITESPACE_BLOCK, "").gsub(/\d/, "") =~ /\A\p{Emoji}[\p{Emoji}\s]*\z/)
  end

  def split_by_emoji
    results = []
    split(//).each do |ch|
      results << case ch
                 when /\d/, WHITESPACE_BLOCK
                   { type: :normal, char: ch }
                 when /\p{Emoji}/
                   { type: :emoji, char: ch }
                 else
                   { type: :normal, char: ch }
                 end
    end
    results.reject { |string| string == "" }
  end
end

module FontMetrics
  # height is the vertical rhythm (see LINE_HEIGHT_FACTOR), which is what the
  # layout advances by. ink_height and ink_above describe where the glyphs
  # actually are: how tall the marks are, and how far the tallest reaches above
  # the baseline. A box or circle drawn around text needs the latter — sized by
  # the rhythm it would stand a head taller than the letters it encloses.
  Metrics = Struct.new(:width, :height, :ink_height, :ink_above)

  # Vertical rhythm is defined deterministically from the font size rather
  # than taken from Pango's font-dependent logical extents. The 1.4 factor
  # reproduces the line height the previous RMagick-based measurement
  # reported for the Latin fonts (45px at a 32px font size), preserving the
  # vertical look of existing trees; Pango's own logical height (~1.03x)
  # would compact every tree by roughly 25%. It also makes the rhythm
  # identical across scripts (the old engine gave JP 1.5x and WenQuanYi
  # 1.25x, so mixed-language documents had inconsistent spacing).
  LINE_HEIGHT_FACTOR = 1.4

  # How far below the baseline the visual centre of a line of text sits.
  #
  # Text is placed by its baseline, so anything meant to sit level with it — a
  # box drawn around it, a rule beside it — has to know where the middle of the
  # marks is. The answer is half the height of a capital, not half of whatever
  # is written: centring on the marks themselves puts the middle of an `s`
  # lower than the middle of a `G`, and centring on the whole cap-to-descender
  # band sits low around digits and capitals, which reach nothing below the
  # baseline and are most of what a label holds.
  def visual_centre(font, fontsize)
    get_metrics("X", font, fontsize, :normal, :normal).ink_above / 2.0
  end

  # Measures text with Pango, the same engine (and the same font fallback
  # resolution) that librsvg uses to render the SVG output, so widths stay
  # consistent with the drawn output for any script. `font` is a
  # comma-separated family list (e.g. FontFamily.for_pango(:sans)).
  def get_metrics(text, font, fontsize, font_style, font_weight)
    layout = pango_layout
    desc = Pango::FontDescription.new
    desc.family = font
    # absolute_size is in device pixels, matching the unitless font-size
    # (px) of the SVG text that librsvg renders.
    desc.absolute_size = fontsize * Pango::SCALE
    desc.style = font_style == :italic ? :italic : :normal
    desc.weight = font_weight == :bold ? :bold : :normal
    layout.font_description = desc
    layout.text = text
    width, = layout.pixel_size
    ink, = layout.pixel_extents
    baseline = layout.baseline / Pango::SCALE.to_f
    Metrics.new(width, fontsize * LINE_HEIGHT_FACTOR, ink.height, baseline - ink.y)
  end

  def pango_layout
    @pango_layout ||= Pango::Layout.new(Pango::CairoFontMap.default.create_context)
  end

  module_function :get_metrics, :pango_layout, :visual_centre
end
