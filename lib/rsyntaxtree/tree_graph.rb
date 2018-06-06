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
# Copyright (c) 2007-2018 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require 'graph'
require 'rmagick'
include Magick

class TreeGraph < Graph

  def initialize(e_list, metrics, symmetrize, color, leafstyle, multibyte,
                 fontstyle, font, font_it, font_bd, font_itbd, font_cjk, font_size,
                 margin)

    # Store class-specific parameters
    @fontstyle  = fontstyle
    @font       = multibyte ? font_cjk : font
    @font_size  = font_size
    @font_it    = font_it
    @font_bd    = font_bd
    @font_itbd  = font_itbd
    @font_cjk   = font_cjk
    @margin     = margin

    super(e_list, metrics, symmetrize, color, leafstyle, multibyte, @font, @font_size)

    # Initialize the image and colors
    @im           = Image.new(@width, @height)
    @im.interlace = PlaneInterlace
    @gc           = Draw.new
    @gc.font      = @font
    @gc.pointsize(@font_size)
  end

  def destroy
    @im.destroy!
  end

  def draw
    parse_list
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
    @im.border!(@margin, @margin, "white")
    return @im.to_blob do
      self.format = fileformat
      self.interlace = PlaneInterlace
    end
  end  

  :private

  # Add the element into the tree (draw it)
  def draw_element(x, y, w, string, type)
    string = string.sub(/\^\z/){""} 
    # Calculate element dimensions and position
    if (type == ETYPE_LEAF) and @leafstyle == "nothing"
      top = row2px(y - 1) + (@font_size * 1.5)
    else 
      top   = row2px(y)
    end
    left   = x + @m[:b_side]
    bottom = top  + @e_height
    right  = left + w

    # Split the string into the main part and the 
    # subscript part of the element (if any)
    parts = string.split("_", 2)
    if(parts.length > 1 )
      main = parts[0].strip
      sub  = parts[1].gsub(/_/, " ").strip
    else
      main = parts[0].strip
      sub  = ""
    end

    if /\A\+(.+)\+\z/ =~ main
      main = $1
      main_decoration = OverlineDecoration
    elsif /\A\-(.+)\-\z/ =~ main
      main = $1
      main_decoration = UnderlineDecoration
    elsif /\A\=(.+)\=\z/ =~ main
      main = $1
      main_decoration = LineThroughDecoration
    else
      main_decoration = NoDecoration
    end

    if /\A\*\*\*(.+)\*\*\*\z/ =~ main
      main = $1
      if !@multibyte
        main_font = @font_itbd
      end
    elsif /\A\*\*(.+)\*\*\z/ =~ main
      main = $1
      if !@multibyte
        main_font = @font_bd
      end
    elsif /\A\*(.+)\*\z/ =~ main
      main = $1
      if !@multibyte
        main_font = @font_it
      end
    else
      main_font = @font
    end

    # Calculate text size for the main and the 
    # subscript part of the element
    # symbols for underline/overline removed temporarily

    main_width = img_get_txt_width(main, main_font, @font_size)

    if /\A\+(.+)\+\z/ =~ sub
      sub = $1
      sub_decoration = OverlineDecoration
    elsif /\A\-(.+)\-\z/ =~ sub
      sub = $1
      @gc.decorate(UnderlineDecoration)
      sub_decoration = UnderlineDecoration
    elsif /\A\=(.+)\=\z/ =~ sub
      sub = $1
      sub_decoration = LineThroughDecoration
    else
      sub_decoration = NoDecoration
    end

    sub_font = @font

    if /\A\*\*\*(.+)\*\*\*\z/ =~ sub
      sub = $1
      if !@multibyte
        sub_font = @font_itbd
      end
    elsif /\A\*\*(.+)\*\*\z/ =~ sub
      sub = $1
      if !@multibyte
        sub_font = @font_bd
      end
    elsif /\A\*(.+)\*\z/ =~ sub
      sub = $1
      if !@multibyte
        sub_font = @font_it
      end
    else
      sub_font = @font
    end

    if sub != ""
      sub_width  = img_get_txt_width(sub.to_s, sub_font, @sub_size)
    else
      sub_width = 0
    end

    # Center text in the element
    txt_width = main_width + sub_width

    txt_pos   = left + (right - left) / 2 - txt_width / 2

    # Select apropriate color
    if(type == ETYPE_LEAF)
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
    main_x = txt_pos
    main_y = top + @e_height - @m[:e_padd]

    @gc.interline_spacing = -(@main_height / 3)
    @gc.font(main_font)
    @gc.decorate(main_decoration)
    @gc.text(main_x.ceil, main_y.ceil, main)

    # Draw subscript text
    if (sub.length > 0 )
      @gc.pointsize(@sub_size)
      sub_x = txt_pos + main_width + @sub_space_width
      sub_y = top + (@e_height - @m[:e_padd] + @sub_size / 2)
      @gc.font(sub_font)
      @gc.decorate(sub_decoration)
      @gc.text(sub_x.ceil, sub_y.ceil, sub)
    end
  end

  # Draw a line between child/parent elements
  def line_to_parent(fromX, fromY, fromW, toX, toW)

    if (fromY == 0 )
      return
    end

    fromTop  = row2px(fromY)
    fromLeft = (fromX + fromW / 2 + @m[:b_side])
    toBot    = (row2px(fromY - 1 ) + @e_height)
    toLeft  = (toX + toW / 2 + @m[:b_side])

    @gc.fill("none")
    @gc.stroke @col_line
    @gc.stroke_width 1
    @gc.line(fromLeft.ceil, fromTop.ceil, toLeft.ceil, toBot.ceil)
  end

  # Draw a triangle between child/parent elements
  def triangle_to_parent(fromX, fromY, fromW, textW, symmetrize = true)
    if (fromY == 0)
      return
    end

    toX = fromX
    fromCenter = (fromX + fromW / 2 + @m[:b_side])

    fromTop  = row2px(fromY).ceil
    fromLeft1 = (fromCenter + textW / 2).ceil
    fromLeft2 = (fromCenter - textW / 2).ceil
    toBot    = (row2px(fromY - 1) + @e_height)
    if symmetrize
      toLeft   = (toX + textW / 2 + @m[:b_side])
    else
      toLeft   = (toX + textW / 2 + @m[:b_side] * 3)
    end

    @gc.fill("none")
    @gc.stroke @col_line
    @gc.stroke_width 1    
    @gc.line(fromLeft1, fromTop, toLeft, toBot)
    @gc.line(fromLeft2, fromTop, toLeft, toBot)
    @gc.line(fromLeft1, fromTop, fromLeft2, fromTop)
  end

  # If a node element text is wider than the sum of it's
  #   child elements, then the child elements need to
  #   be resized to even out the space. This function
  #   recurses down the a child tree and sizes the
  #   children appropriately.
  def fix_child_size(id, current, target)
    children = @e_list.get_children(id)
    @e_list.set_element_width(id, target)

    if(children.length > 0 ) 
      delta = target - current
      target_delta = delta / children.length 

      children.each do |child|
        child_width = @e_list.get_element_width(child)
        fix_child_size(child, child_width, child_width + target_delta)
      end
    end
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
end
