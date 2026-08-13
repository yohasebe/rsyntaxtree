# frozen_string_literal: true

#==========================
# utils.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require 'rmagick'
require 'pango'

# Font family lists shared by the SVG output and the Pango-based text
# measurement. Each entry is an ordered list of family names; the FontFamily
# helpers format it for SVG (quoted) or for Pango::FontDescription#family
# (unquoted). Keeping a single source guarantees that measurement and
# rendering resolve through the same fallback chain.
FONT_FAMILIES = {
  sans:  ["Noto Sans", "Noto Sans JP", "OpenMoji", "OpenMoji Color", "OpenMoji Black", "sans-serif"].freeze,
  serif: ["Noto Serif", "Noto Serif JP", "OpenMoji", "OpenMoji Color", "OpenMoji Black", "serif"].freeze,
  mono:  ["Noto Sans Mono SemiCondensed", "Noto Sans JP", "OpenMoji", "OpenMoji Color", "OpenMoji Black", "sans-serif"].freeze,
  cjk:   ["WenQuanYi Zen Hei", "Noto Sans", "OpenMoji", "OpenMoji Color", "OpenMoji Black", "sans-serif"].freeze
}.freeze

module FontFamily
  # cjk_priority: put the JP font first (mirrors the e[:cjk] branch in
  # SVGGraph#draw_element). No-op for the :cjk style, which has no variant.
  def list(style, cjk_priority: false)
    families = FONT_FAMILIES.fetch(style.to_sym).dup
    families[0], families[1] = families[1], families[0] if cjk_priority && style.to_sym != :cjk
    families
  end

  def for_svg(style, cjk_priority: false)
    list(style, cjk_priority: cjk_priority).map { |name| name.include?(" ") ? "'#{name}'" : name }.join(", ")
  end

  def for_pango(style, cjk_priority: false)
    list(style, cjk_priority: cjk_priority).join(", ")
  end

  module_function :list, :for_svg, :for_pango
end

class String
  def contains_cjk?
    !!(gsub(WHITESPACE_BLOCK, "") =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}|[^\x01-\x7E]/)
  end

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
  Metrics = Struct.new(:width, :height)

  # Vertical rhythm is defined deterministically from the font size rather
  # than taken from Pango's font-dependent logical extents. The 1.4 factor
  # reproduces the line height the previous RMagick-based measurement
  # reported for the Latin fonts (45px at a 32px font size), preserving the
  # vertical look of existing trees; Pango's own logical height (~1.03x)
  # would compact every tree by roughly 25%. It also makes the rhythm
  # identical across scripts (the old engine gave JP 1.5x and WenQuanYi
  # 1.25x, so mixed-language documents had inconsistent spacing).
  LINE_HEIGHT_FACTOR = 1.4

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
    Metrics.new(width, fontsize * LINE_HEIGHT_FACTOR)
  end

  def pango_layout
    @pango_layout ||= Pango::Layout.new(Pango::CairoFontMap.default.create_context)
  end

  module_function :get_metrics, :pango_layout
end
