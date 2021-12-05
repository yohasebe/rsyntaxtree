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
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

class ErrorMessage

  def initialize(text, font, font_size, filename, format)

    @text = text
    @font = font
    @font_size = font_size
    @filename = filename
    @format = format

    metrics = img_get_txt_metrics(text, font, font_size, NoDecoration, true)

    @im = Image.new(metrics.width, metrics.height)
    @gc = Draw.new
    @gc.font = font
    @gc.pointsize = font_size
    @gc.stroke("transparent")
    @gc.fill("black")
    @gc.gravity(CenterGravity)
    @gc.text(0, 0, text)
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

  def draw
    @gc.draw(@im)
  end

  def save
    @gc.draw(@im)
    @im.write(@filename + "." + @format)
  end

end
