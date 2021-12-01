#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# svg_graph.rb
#==========================
#
# Parses an element list into an SVG tree.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require "tempfile"
require 'graph'

class SVGGraph < Graph

  def initialize(e_list, metrics, symmetrize, color, leafstyle, multibyte, fontstyle, font, font_cjk, font_size)

    # Store class-specific parameters
    @font       = multibyte ? font_cjk : font
    @font_size  = font_size
    case fontstyle
    when /(?:sans|cjk)/
      @fontstyle  = "sans-serif"
    when /(?:serif|math)/
      @fontstyle  = "serif"
    end

    super(e_list, metrics, symmetrize, color, leafstyle, multibyte, @font, @font_size)

    @line_styles  = "<line style='stroke:black; stroke-width:#{FONT_SCALING};' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
    @polygon_styles  = "<polygon style='fill: none; stroke: black; stroke-width:#{FONT_SCALING};' points='X1 Y1 X2 Y2 X3 Y3' />\n"
    @text_styles  = "<text style='fill: COLOR; font-size: FONT_SIZEpx; ST; WA;' x='X_VALUE' y='Y_VALUE' TD font-family='#{@fontstyle}'>CONTENT</text>\n"
    @tree_data  = String.new
  end

  def svg_data
    parse_list
    header =<<EOD
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
 "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="#{@width}" height="#{@height}" version="1.1" xmlns="http://www.w3.org/2000/svg">
EOD

    footer = "</svg>"
    header + @tree_data + footer
  end

  # Create a temporary file and returns only its filename
  def create_tempf(basename, ext, num = 10)
    flags = File::RDWR | File::CREAT | File::EXCL
    tfname = ""
    num.times do |i|
      begin
        tfname = "#{basename}.#{$$}.#{i}.#{ext}"
        tfile = File.open(tfname, flags, 0600)
      rescue Errno::EEXIST
        next
      end
      tfile.close
      return tfname
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

    if /\A\=(.+)\=\z/ =~ main
      main = $1
      main_decoration= "overline"
    elsif /\A\-(.+)\-\z/ =~ main
      main = $1
      main_decoration= "underline"
    else
      main_decoration= ""
    end

    if /\A\*\*\*(.+)\*\*\*\z/ =~ main
      main = $1
      main_style = "font-style: italic"
      main_weight = "font-weight: bold"
    elsif /\A\*\*(.+)\*\*\z/ =~ main
      main = $1
      main_style = ""
      main_weight = "font-weight: bold"
    elsif /\A\*(.+)\*\z/ =~ main
      main = $1
      main_style = "font-style: italic"
      main_weight = ""
    else
      main_style = ""
      main_weight = ""
    end

    if /\A#(.+)#\z/ =~ main
      main = $1
    end

    # Calculate text size for the main and the 
    # subscript part of the element
    # symbols for underline/overline removed temporarily

    main_width = img_get_txt_width(main, @font, @font_size)

    if sub != ""
      if /\A\=(.+)\=\z/ =~ sub
        sub = $1
        sub_decoration= "overline"
      elsif /\A\-(.+)\-\z/ =~ sub
        sub = $1
        sub_decoration= "underline"
      else
        sub_decoration= ""
      end

      if /\A\*\*\*(.+)\*\*\*\z/ =~ sub
        sub = $1
        sub_style = "font-style: italic"
        sub_weight = "font-weight: bold"
      elsif /\A\*\*(.+)\*\*\z/ =~ sub
        sub = $1
        sub_style = ""
        sub_weight = "font-weight: bold"
      elsif /\A\*(.+)\*\z/ =~ sub
        sub = $1
        sub_style = "font-style: italic"
        sub_weight = ""
      else
        sub_style = ""
        sub_weight = ""
      end
      sub_width  = img_get_txt_width(sub.to_s,  @font, @sub_size)
    else
      sub_width = 0
    end

    if /\A#(.+)#\z/ =~ sub
      sub = $1
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

    # Draw main text
    main_data  = @text_styles.sub(/COLOR/, col)
    main_data  = main_data.sub(/FONT_SIZE/, @font_size.to_s)
    main_x = txt_pos
    main_y = top + @e_height - @m[:e_padd] * 1.5
    main_data  = main_data.sub(/X_VALUE/, main_x.to_s)
    main_data  = main_data.sub(/Y_VALUE/, main_y.to_s)

    @tree_data += main_data.sub(/TD/, "text-decoration='#{main_decoration}'")
      .sub(/ST/, main_style)
      .sub(/WA/, main_weight)
      .sub(/CONTENT/, main)

    # Draw subscript text
    sub_data  = @text_styles.sub(/COLOR/, col)
    sub_data  = sub_data.sub(/FONT_SIZE/, @sub_size.to_s)
    sub_x = main_x + main_width
    sub_y = top + (@e_height - @m[:e_padd] + @sub_size / 10)
    if (sub.length > 0 )
      sub_data   = sub_data.sub(/X_VALUE/, sub_x.ceil.to_s)
      sub_data   = sub_data.sub(/Y_VALUE/, sub_y.ceil.to_s)
      @tree_data += sub_data.sub(/TD/, "text-decoration='#{sub_decoration}'")
        .sub(/ST/, sub_style)
        .sub(/WA/, sub_weight)
        .sub(/CONTENT/, sub)
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

    line_data   = @line_styles.sub(/X1/, fromLeft.ceil.to_s)
    line_data   = line_data.sub(/Y1/, fromTop.ceil.to_s)
    line_data   = line_data.sub(/X2/, toLeft.ceil.to_s)
    @tree_data += line_data.sub(/Y2/, toBot.ceil.to_s)

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

    polygon_data = @polygon_styles.sub(/X1/, fromLeft1.ceil.to_s)
    polygon_data = polygon_data.sub(/Y1/, fromTop.ceil.to_s)
    polygon_data = polygon_data.sub(/X2/, fromLeft2.ceil.to_s)
    polygon_data = polygon_data.sub(/Y2/, fromTop.ceil.to_s)
    polygon_data = polygon_data.sub(/X3/, toLeft.ceil.to_s)
    @tree_data  += polygon_data.sub(/Y3/, toBot.ceil.to_s)
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
end
