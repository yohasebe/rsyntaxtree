#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# imgutils.rb
#==========================
#
# Image utility functions to inspect text font metrics
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2018 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# require 'rubygems'
require 'rmagick'
include Magick

class String
  def contains_cjk?
    !!(self =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/)
  end
end

def img_get_txt_metrics(text, font, font_size, multiline)

  background = Image.new(500, 250)

  gc = Draw.new
  gc.annotate(background, 0, 0, 0, 0, text) do |gc|
    gc.font = font
    gc.pointsize = font_size
    gc.gravity = CenterGravity
    gc.stroke = 'none'
  end

  if multiline
    metrics = gc.get_multiline_type_metrics(background, text)
  else
    metrics = gc.get_type_metrics(background, text)
  end

  return metrics
end

def get_txt_only(text)
  text = text.strip
  if /\A([\+\-\=\*]+).+/ =~ text
    prefix = $1
    prefix_l = Regexp.escape(prefix)
    prefix_r = Regexp.escape(prefix.reverse)
    if /\A#{prefix_l}(.+)#{prefix_r}\z/ =~ text
      return $1
    end
  end
  return text
end

def img_get_txt_width(text, font, font_size, multiline = false)
  parts = text.split("_", 2)
  main_before = parts[0].strip
  sub = parts[1]
  main = get_txt_only(main_before)
  main_metrics = img_get_txt_metrics(main, font, font_size, multiline)
  width = main_metrics.width
  if sub
    sub_metrics = img_get_txt_metrics(sub.strip, font, font_size * SUBSCRIPT_CONST, multiline)
    width += sub_metrics.width
  end
  return width
end

def img_get_txt_width2(text, font, font_size, multiline = false)
  parts = text.split("_", 2)
  main_before = parts[0].strip
  sub = parts[1]
  main = get_txt_only(main_before)
  if(main.contains_cjk?)
    main = 'n' * main.strip.size * 2
  else
    main
  end
  main_metrics = img_get_txt_metrics(main, font, font_size, multiline)
  width = main_metrics.width
  if sub
    if(sub.contains_cjk?)
      sub = 'n' * sub.strip.size * 2
    else
      sub
    end
    sub_metrics = img_get_txt_metrics(sub, font, font_size * SUBSCRIPT_CONST, multiline)
    width += sub_metrics.width
  end
  return width
end

def img_get_txt_height(text, font, font_size, multiline = false)
  metrics = img_get_txt_metrics(text, font, font_size, multiline)
  y = metrics.height
  return y
end
