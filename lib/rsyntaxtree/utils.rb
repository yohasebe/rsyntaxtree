#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# utils.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>

require 'rmagick'
include Magick

class String
  def contains_cjk?
    !!(self.gsub(WHITESPACE_BLOCK, "") =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}|[^\x01-\x7E]/)
  end

  def contains_emoji?
    !!(self.gsub(WHITESPACE_BLOCK, "").gsub(/\d/, "") =~ /\p{Emoji}/)
  end

  def all_emoji?
    !!(self.gsub(WHITESPACE_BLOCK, "").gsub(/\d/, "") =~ /\A\p{Emoji}[\p{Emoji}\s]*\z/)
  end

  def split_by_emoji
    results = []
    self.split(//).each do |ch|
      case ch
      when /\d/, WHITESPACE_BLOCK
        results << {:type => :normal, :char => ch}
      when /\p{Emoji}/
        results << {:type => :emoji, :char => ch}
      else
        results << {:type => :normal, :char => ch}
      end
    end
    results.reject{|string| string == ""}
  end
end

module FontMetrics
  def get_metrics(text, font, fontsize, font_style, font_weight)
    background = Image.new(1, 1)
    gc = Draw.new
    gc.annotate(background, 0, 0, 0, 0, text) do |gc|
      gc.font = font
      gc.font_style = font_style == :italic ? ItalicStyle : NormalStyle
      gc.font_weight = font_weight == :bold ? BoldWeight : NormalWeight
      gc.pointsize = fontsize
      gc.gravity = CenterGravity
      gc.stroke = 'none'
      gc.kerning = 0
      gc.interline_spacing = 0
      gc.interword_spacing = 0
    end
    metrics = gc.get_multiline_type_metrics(background, text)
    return metrics
  end
  module_function :get_metrics
end

