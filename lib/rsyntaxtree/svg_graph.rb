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

  def initialize(e_list, metrics, symmetrize, color, leafstyle, multibyte, fontstyle, font, font_cjk, font_size, margin, transparent)

    # Store class-specific parameters
    @font       = multibyte ? font_cjk : font
    @font_size  = font_size
    @transparent = transparent

    case fontstyle
    when /(?:sans|cjk)/
      @fontstyle = "\"'Noto Sans JP', 'Noto Sans', sans-serif\""
      @fontcss = "http://fonts.googleapis.com/earlyaccess/notosansjp.css"
    when /(?:serif)/
      @fontstyle = "\"'Noto Serif JP', 'Noto Serif', serif\""
      @fontcss = "https://fonts.googleapis.com/css?family=Noto+Serif+JP"
    when /(?:math)/
      @fontstyle = "\"Latin Modern Roman', sans-serif\""
      @fontcss = "https://cdn.jsdelivr.net/gh/sugina-dev/latin-modern-web@1.0.1/style/latinmodern-roman.css"
    end

    @margin     = margin.to_i

    super(e_list, metrics, symmetrize, color, leafstyle, multibyte, @fontstyle, @font_size)

    @line_styles  = "<line style='stroke:black; stroke-width:#{FONT_SCALING};' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
    @polygon_styles  = "<polygon style='fill: none; stroke: black; stroke-width:#{FONT_SCALING};' points='X1 Y1 X2 Y2 X3 Y3' />\n"
    @text_styles  = "<text letter-spacing='0' word-spacing='0' kerning='0' style='fill: COLOR; font-size: FONT_SIZE ST WA' x='X_VALUE' y='Y_VALUE' TD font-family=#{@fontstyle}>CONTENT</text>\n"
    @tree_data  = String.new
  end

  def get_left_most(tree_data)
    xs = @tree_data.scan(/x1?=['"]([^'"]+)['"]/).map{|m| m.first.to_i}
    xs.min
  end

  def svg_data
    parse_list
    lm = get_left_most(@tree_data)
    width = @width - lm + @margin * 2
    height = @height + @margin * 2
    x1 = -@margin + lm
    y1 = -@margin
    x2 = @width - lm * 1.5 + @margin * 2
    y2 = @height + @margin * 2

     header =<<EOD
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
  <svg width="#{width}" height="#{height}" viewBox="#{x1}, #{y1}, #{x2}, #{y2}" version="1.1" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <style>
        @import url(#{@fontcss});
      </style>
    </defs>
EOD

    rect =<<EOD
<rect x="#{x1}" y="#{y1}" width="#{x2}" height="#{y2}" stroke="none" fill="white" />"
EOD


    footer = "</svg>"

    if @transparent
      header + @tree_data + footer
    else
      header + rect + @tree_data + footer
    end
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
      main_decoration= "overline"
    elsif /\A\-(.+)\-\z/ =~ main
      main = $1
      main_decoration= "underline"
    elsif /\A\~(.+)\~\z/ =~ main
      main = $1
      main_decoration= "line-through"
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

    main_width = 0
    main_height = 0
    main.split(/\\n/).each do |l|
      l_width = img_get_txt_width(l, @font, @font_size)
      main_width = l_width if main_width < l_width
      main_height += img_get_txt_height(l, @font, @font_size)
    end


    if sub != ""
      if /\A\=(.+)\=\z/ =~ sub
        sub = $1
        sub_decoration= "overline"
      elsif /\A\-(.+)\-\z/ =~ sub
        sub = $1
        sub_decoration= "underline"
      elsif /\A\~(.+)\~\z/ =~ sub
        sub = $1
        sub_decoration= "line-through"
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
      sub_height = img_get_txt_height(sub, @font, @font_size)
      sub_width  = img_get_txt_width(sub.to_s,  @font, @sub_size)
    else
      sub_width = 0
      sub_height = 0
    end

    if /\A#(.+)#\z/ =~ sub
      sub = $1
    end

    # Center text in the element
    txt_pos   = left + (right - left) / 2

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
    main_data  = main_data.sub(/FONT_SIZE/, @font_size.to_s + "px;")
    main_x = txt_pos - (main_width + sub_width) / 2
    main_y = top + @e_height - @m[:e_padd]
    main_data  = main_data.sub(/X_VALUE/, main_x.to_s)
    main_data  = main_data.sub(/Y_VALUE/, main_y.to_s)
    if /\\n/ =~ main
      lines = main.split(/\\n/)
      new_main = ""
      dy = 0
      lines.each_with_index do |l, idx|
        if idx == 0
          dy = 0
        else
          dy = 1
          main_y += img_get_txt_height(l, @font, @font_size)
        end
        this_width = img_get_txt_width(l,  @font, @font_size)
        this_x = txt_pos - (this_width + sub_width) / 2
        new_main << "<tspan x='#{this_x}' y='#{main_y}'>#{l}</tspan>"
        @height = main_y if main_y > @height
      end
      main = new_main
    end
    @tree_data += main_data.sub(/TD/, "text-decoration='#{main_decoration}'")
      .sub(/ST/, main_style + ";")
      .sub(/WA/, main_weight + ";")
      .sub(/CONTENT/, main)

    # Draw subscript text
    if sub && sub != ""
      sub_data  = @text_styles.sub(/COLOR/, col)
      sub_data  = sub_data.sub(/FONT_SIZE/, @sub_size.to_s)
      sub_x  = txt_pos + (main_width / 2) - (sub_width / 2)
      if sub_mode == "__"
        sub_y = main_y - sub_height / 3
      else
        sub_y = main_y + sub_height / 4
      end
      sub_data   = sub_data.sub(/X_VALUE/, sub_x.to_s)
      sub_data   = sub_data.sub(/Y_VALUE/, sub_y.to_s)
      @tree_data += sub_data.sub(/TD/, "text-decoration='#{sub_decoration}'")
        .sub(/ST/, sub_style)
        .sub(/WA/, sub_weight)
        .sub(/CONTENT/,   sub)
      @height += sub_height / 4 if sub_mode == "_"
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

    line_data   = @line_styles.sub(/X1/, fromLeft.to_s)
    line_data   = line_data.sub(/Y1/, fromTop.to_s)
    line_data   = line_data.sub(/X2/, toLeft.to_s)
    @tree_data += line_data.sub(/Y2/, toBot.to_s)

  end

  # Draw a triangle between child/parent elements
  def triangle_to_parent(fromX, fromY, fromW, textW, symmetrize = true)
    if (fromY == 0)
      return
    end

    toX = fromX
    fromCenter = (fromX + fromW / 2 + @m[:b_side])

    fromTop  = row2px(fromY)
    fromLeft1 = (fromCenter + textW / 2)
    fromLeft2 = (fromCenter - textW / 2)
    toBot    = (row2px(fromY - 1) + @e_height)

    if symmetrize
      toLeft   = (toX + textW / 2 + @m[:b_side])
    else
      toLeft   = (toX + textW / 2 + @m[:b_side] * 3)
    end

    polygon_data = @polygon_styles.sub(/X1/, fromLeft1.to_s)
    polygon_data = polygon_data.sub(/Y1/, fromTop.to_s)
    polygon_data = polygon_data.sub(/X2/, fromLeft2.to_s)
    polygon_data = polygon_data.sub(/Y2/, fromTop.to_s)
    polygon_data = polygon_data.sub(/X3/, toLeft.to_s)
    @tree_data  += polygon_data.sub(/Y3/, toBot.to_s)
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

  def img_get_txt_width(text, font, font_size, multiline = true)
    parts = text.split(/__?/, 2)
    main_before = parts[0].strip
    sub = parts[1]
    main = get_txt_only(main_before)
    main_metrics = img_get_txt_metrics(main, font, font_size, multiline)
    width = main_metrics.width
    if sub
      sub_metrics = img_get_txt_metrics(sub, font, font_size * SUBSCRIPT_CONST, multiline)
      width += sub_metrics.width
    end
    return width
  end

  def img_get_txt_height(text, font, font_size)
    main_metrics = img_get_txt_metrics(text, font, font_size, false)
    main_metrics.height
  end

end
