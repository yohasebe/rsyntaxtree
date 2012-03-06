#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# error_message.rb
#==========================
#
# Takes an error message and drow an image file of the very message
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

require 'imgutils'

class ErrorMessage

  def initialize(text, font, font_size, filename, format)

    @text = text
    @font = font
    @font_size = font_size
    @filename = filename
    @format = format
    
    metrics = img_get_txt_metrics(text, font, font_size, true)

    @im = Image.new(metrics.width, metrics.height)
    @gc = Draw.new
    @gc.font = font
    @gc.pointsize = font_size
    @gc.stroke("transparent")
    @gc.fill("black")
    @gc.gravity(CenterGravity)
    @gc.text(0, 0, text)
  end

  def draw
    @gc.draw(@im)
  end

  def save
    @gc.draw(@im)
    @im.write(@filename + "." + @format)
  end

end
