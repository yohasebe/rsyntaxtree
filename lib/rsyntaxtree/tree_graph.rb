#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# tree_graph.rb
#==========================
#
# Parses an element list into a (non-SVG) graphical tree.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require 'graph'
require 'rmagick'
include Magick

class TreeGraph < Graph

  def initialize(e_list, symmetrize, color, leafstyle, having_cjk, having_emoji, fontstyle, font, font_it, font_bd, font_itbd, font_math, font_cjk, font_emoji, font_size, margin, transparent, vspace)

    @width = 0
    @height = 0

    # Store class-specific parameters
    if having_cjk
      @font = font_cjk
    else
      @font = font
    end
    @fontstyle   = fontstyle
    if fontstyle == "math" && having_cjk
      @font = font_cjk
    end

    @having_cjk   = having_cjk
    @having_emoji = having_emoji
    @font_emoji   = font_emoji
    @font_size    = font_size
    @font_it      = font_it
    @font_bd      = font_bd
    @font_itbd    = font_itbd
    @font_math    = font_math
    @font_cjk     = font_cjk
    @margin       = margin
    @transparent  = transparent

    super(e_list, symmetrize, color, leafstyle, having_cjk, having_emoji, @font, @font_size, vspace)

    # Initialize the image and colors
    @gc           = Draw.new
    @gc.font      = @font
    @gc.pointsize(@font_size)
  end

  def destroy
    @im.destroy!
  end

  def draw
    metrics = parse_list
    @width = metrics[:width]
    @height = metrics[:height]
    @im = Image.new(@width, @height)
    if @transparent
      @im.matte_reset!
    end
    @im.interlace = PlaneInterlace
    @gc.draw(@im)
  end

  def save(filename)
    draw
    @im.write(filename)
  end

  # inspired by the implementation of Gruff
  # by Geoffrey Grosenbach
  def to_blob(fileformat='PNG')
    draw
    # @im.trim!
    if @transparent
      @im.border!(@margin, @margin, "transparent")
    else
      @im.border!(@margin, @margin, "white")
    end
    @im.format = fileformat
    @im.interlace = PlaneInterlace
    return @im.to_blob
  end

  :private

  # Add the element into the tree (draw it)
  def draw_element(element)
    string = element.content.sub(/\^\z/){""}
    top = element.vertical_indent 
    left   = element.horizontal_indent
    right  = left + element.content_width 

    parts = string.split(/(__?)/)
    if(parts.length === 3 )
      main = parts[0].strip
      sub_mode = parts[1]
      sub  = parts[2].strip
    else
      main = parts[0].strip
      sub_mode = ""
      sub  = ""
    end

    if /\A\=(.+)\=\z/ =~ main
      main = $1
      main_decoration = OverlineDecoration
    elsif /\A\-(.+)\-\z/ =~ main
      main = $1
      main_decoration = UnderlineDecoration
    elsif /\A\~(.+)\~\z/ =~ main
      main = $1
      main_decoration = LineThroughDecoration
    else
      main_decoration = NoDecoration
    end

    main_font = @font

    if /\A\*\*\*(.+)\*\*\*\z/ =~ main
      main = $1
      if !@having_cjk && !@having_emoji
        main_font = @font_itbd
      end
    elsif /\A\*\*(.+)\*\*\z/ =~ main
      main = $1
      if !@having_cjk && !@having_emoji
        main_font = @font_bd
      end
    elsif /\A\*(.+)\*\z/ =~ main
      main = $1
      if !@having_cjk && !@having_emoji
        main_font = @font_it
      end
    end

    if /\A#(.+)#\z/ =~ main
      main = $1
      main_font = @font_math
    end

    # Calculate text size for the main and the
    # subscript part of the element

    main_width = 0
    main_height = 0
    main.split(/\\n/).each do |l|
      if @having_emoji && l.all_emoji?
        main_font = @font_emoji
      end
      l_width = img_get_txt_width(l, main_font, @font_size)
      main_width = l_width if main_width < l_width
      main_height += img_get_txt_height(l, @font, @font_size)
    end

    if /\A\=(.+)\=\z/ =~ sub
      sub = $1
      sub_decoration = OverlineDecoration
    elsif /\A\-(.+)\-\z/ =~ sub
      sub = $1
      sub_decoration = UnderlineDecoration
    elsif /\A\~(.+)\~z/ =~ sub
      sub = $1
      sub_decoration = LineThroughDecoration
    else
      sub_decoration = NoDecoration
    end

    sub_font = @font
    if /\A\*\*\*(.+)\*\*\*\z/ =~ sub
      sub = $1
      if !@having_cjk && !@having_emoji
        sub_font = @font_itbd
      end
    elsif /\A\*\*(.+)\*\*\z/ =~ sub
      sub = $1
      if !@having_cjk && !@having_emoji
        sub_font = @font_bd
      end
    elsif /\A\*(.+)\*\z/ =~ sub
      sub = $1
      if !@having_cjk && !@having_emoji
        sub_font = @font_it
      end
    end

    if /\A#(.+)#\z/ =~ sub
      sub = $1
      sub_font = @font_math
    end

    if sub != ""
      if @having_emoji && sub.all_emoji?
        sub_font = @font_emoji
      end
      sub_width  = img_get_txt_width(sub.to_s, sub_font, @sub_size)
      sub_height  = img_get_txt_height(sub.to_s, sub_font, @sub_size)
    else
      sub_width = 0
      sub_height = 0
    end

    # Center text in the element
    txt_pos   = left + (right - left) / 2

    # Select apropriate color
    if(element.type == ETYPE_LEAF)
      col = @col_leaf
    else
      col = @col_node
    end

    if(main[0].chr == "<" && main[-1].chr == ">")
      col = @col_trace
    end

    @gc.stroke("none")
    @gc.fill(col)

    # Draw main text
    @gc.pointsize(@font_size)
    @gc.kerning = 0
    @gc.interline_spacing = 0
    @gc.interword_spacing = 0

    main_x = txt_pos - sub_width / 2
    main_y = top + @e_height - @connector_to_text

    @gc.decorate(main_decoration)
    numlines = main.count("\\n")
    @gc.text_align(CenterAlign)
    main_txt = main.gsub("\\n", "\n")
    if @having_emoji && main_txt.all_emoji?
      main_font = @font_emoji
    end
    @gc.font(main_font)
    @gc.text(main_x.ceil, main_y.ceil, main_txt)

    # Draw subscript text
    if (sub != "" )
      @gc.pointsize(@sub_size)
      sub_x = main_x + (main_width / 2) + (sub_width / 2)

      if sub_mode == "__"
        sub_y = top + main_height - sub_height / 2
      else
        sub_y = top + main_height + sub_height / 4
      end

      @gc.decorate(sub_decoration)
      @gc.text_align(CenterAlign)
      sub_txt = sub.gsub("\\n", "\n")
      if @having_emoji && sub_txt.all_emoji?
        sub_font = @font_emoji
      end
      @gc.font(sub_font)
      @gc.text(sub_x.ceil, sub_y.ceil, " " + sub_txt)
    end
  end

  # Draw a line between child/parent elements
  def line_to_parent(parent, child)

    if (child.horizontal_indent == 0 )
      return
    end

    x1 = child.horizontal_indent + child.content_width / 2
    y1 = child.vertical_indent
    x2 = parent.horizontal_indent + parent.content_width / 2
    y2 = parent.vertical_indent + parent.content_height

    @gc.fill("none")
    @gc.stroke @col_line
    @gc.stroke_width 1 * FONT_SCALING
    @gc.line(x1, y1, x2, y2)
  end

  # Draw a triangle between child/parent elements
  def triangle_to_parent(parent, child)
    if (child.horizontal_indent == 0)
      return
    end

    x1 = child.horizontal_indent
    y1 = child.vertical_indent
    x2 = child.horizontal_indent + child.content_width
    y2 = child.vertical_indent
    x3 = parent.horizontal_indent + parent.content_width / 2
    y3 = parent.vertical_indent + parent.content_height

    @gc.fill("none")
    @gc.stroke @col_line
    @gc.stroke_width 1 * FONT_SCALING
    @gc.line(x1, y1, x3, y3)
    @gc.line(x2, y2, x3, y3)
    @gc.line(x1, y1, x2, y2)
  end
end
