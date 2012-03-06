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
# Copyright (c) 2007-2009 Yoichiro Hasebe <yohasebe@gmail.com>
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

require 'rubygems'
require 'RMagick'
include Magick

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

def img_get_txt_width(text, font = "Verdana", font_size = 10, multibyte = false)

  metrics = img_get_txt_metrics(text, font, font_size, multibyte)
  x = metrics.width
  return x
  
end

def img_get_txt_height(text, font = "Verdana", font_size = 10, multibyte = false)

  metrics = img_get_txt_metrics(text, font, font_size, multibyte)
  y = metrics.height
  return y
  
end
 
