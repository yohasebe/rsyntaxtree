# frozen_string_literal: true

#==========================
# utils.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2023 Yoichiro Hasebe <yohasebe@gmail.com>

require 'rmagick'

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
  def get_metrics(text, font, fontsize, font_style, font_weight)
    background = Magick::Image.new(1, 1)
    gc = Magick::Draw.new
    gc.annotate(background, 0, 0, 0, 0, text) do |gca|
      gca.font = font
      gca.font_style = font_style == :italic ? Magick::ItalicStyle : Magick::NormalStyle
      gca.font_weight = font_weight == :bold ? Magick::BoldWeight : Magick::NormalWeight
      gca.pointsize = fontsize
      gca.gravity = Magick::CenterGravity
      gca.stroke = 'none'
      gca.kerning = 0
      gca.interline_spacing = 0
      gca.interword_spacing = 0
    end
    gc.get_multiline_type_metrics(background, text)
  end
  module_function :get_metrics
end
