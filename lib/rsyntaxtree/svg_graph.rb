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
require 'utils'

class SVGGraph < Graph

  def initialize(e_list, symmetrize, color, leafstyle, fontstyle, fontset, fontsize, margin, transparent, vspace)

    @height = 0
    @width  = 0

    @extra_lines = []

    @fontset  = fontset
    @fontsize  = fontsize
    @transparent = transparent
    @fontstyle = fontstyle

    # if color
    #   openmoji = "OpenMojiColor"
    # else
    #   openmoji = "OpenMojiBlack"
    # end
    # @fontstyle = "'#{openmoji}', " + @fontstyle

    @margin = margin.to_i

    super(e_list, symmetrize, color, leafstyle, @fontset, @fontsize, vspace)

    @line_styles  = "<line style='stroke:black; stroke-width:#{FONT_SCALING};' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
    @polygon_styles  = "<polygon style='fill: none; stroke: black; stroke-width:#{FONT_SCALING};' points='X1 Y1 X2 Y2 X3 Y3' />\n"
    @text_styles  = "<text alignment-baseline='text-top' style='fill: COLOR; font-size: fontsize' x='X_VALUE' y='Y_VALUE'>CONTENT</text>\n"
    @tree_data  = String.new
  end

  def svg_data
    metrics = parse_list
    @height = metrics[:height] + @margin * 2
    @width = metrics[:width] + @margin * 2

    x1 = 0 - @margin
    y1 = 0 - @margin
    x2 = @width + @margin
    y2 = @height + @margin
    extra_lines = @extra_lines.join("\n")

     header =<<EOD
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
  <svg width="#{@width}" height="#{@height}" viewBox="#{x1}, #{y1}, #{x2}, #{y2}" version="1.1" xmlns="http://www.w3.org/2000/svg">
EOD

    rect =<<EOD
<rect x="#{x1}" y="#{y1}" width="#{x2}" height="#{y2}" stroke="none" fill="white" />"
EOD

    footer = "</svg>"

    if @transparent
      header + @tree_data + extra_lines + footer
    else
      header + rect + @tree_data + extra_lines + footer
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
  def draw_element(element)
    top  = element.vertical_indent
    left   = element.horizontal_indent
    bottom = top  + @e_height
    right  = left + element.content_width

    # Center text in the element
    txt_pos = left + (right - left) / 2

    # Select apropriate color
    if(element.type == ETYPE_LEAF)
      col = @col_leaf
    else
      col = @col_node
    end

    # Draw text
    text_data = @text_styles.sub(/COLOR/, col)
    text_data = text_data.sub(/fontsize/, @fontsize.to_s + "px;")
    text_x = txt_pos - element.content_width / 2
    text_y = top + @e_height - @connector_to_text
    text_data  = text_data.sub(/X_VALUE/, text_x.to_s)
    text_data  = text_data.sub(/Y_VALUE/, text_y.to_s)
    new_text = ""
      this_x = 0
      this_y = 0
    bc = {:x => text_x - @horizontal_spacing / 2 , :y => top, :width => element.content_width + @horizontal_spacing, :height => nil}
    element.content.each_with_index do |l, idx|
      case l[:type]
      when :border
        x1 = text_x
        if idx == 0
          text_y -= l[:height]
        elsif
          text_y += l[:height]
        end
        y1 = text_y
        x2 = text_x + element.content_width
        y2 = y1
        this_width = x2 - x1
        @extra_lines << "<line style=\"stroke:#{col}; stroke-width:2; \" x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\"></line>"
      when :blankline
        text_y += l[:height] if idx != 0
        new_text << "<tspan y='#{text_y}'></tspan>"
      else
        this_x = txt_pos - l[:elements].map{|e| e[:width]}.sum / 2
        text_y += l[:elements].map{|e| e[:height]}.max if idx != 0
        l[:elements].each do |e|
          style = "style=\""

          baseline = ""
          if e[:decoration].include?(:superscript)
            this_y = text_y - e[:height] * 0.2
            style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
          elsif e[:decoration].include?(:subscript)
            this_y = text_y + e[:height] * 0.2
            style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
          else
            this_y = text_y
          end

          if e[:decoration].include?(:bold) || e[:decoration].include?(:bolditalic)
            style += "font-weight: bold; "
          end
          if e[:decoration].include?(:italic) || e[:decoration].include?(:bolditalic)
            style += "font-style: italic; "
          end

          style += "\""

          case @fontstyle
          when /(?:sans|cjk)/
            if e[:cjk]
              fontstyle = "'Noto Sans JP', 'Noto Sans', sans-serif"
            else
              fontstyle = "'Noto Sans', 'Noto Sans JP', sans-serif"
            end
          when /(?:serif)/
            if e[:cjk]
              fontstyle = "'Noto Serif JP', 'Noto Serif', serif"
            else
              fontstyle = "'Noto Serif', 'Noto Serif JP', serif"
            end
          end

          new_text << "<tspan x='#{this_x}' y='#{this_y}' #{baseline} #{style} font-family=\"#{fontstyle}\">#{e[:text]}</tspan>"

          if e[:decoration].include?(:box)
            box_width = e[:width]
            box_height = e[:height] 
            # if e[:decoration].include?(:superscript)
            #   box_y = this_y - e[:height] * 0.8
            # elsif e[:decoration].include?(:subscript)
            #   box_y = this_y - e[:height] * 0.8
            # else
            box_y = this_y - e[:height] * 0.8
            # end
            box_x = this_x
            rect = "<rect style='fill: none; stroke: #{col}; stroke-width:#{FONT_SCALING};' x='#{box_x}' y='#{box_y}' width='#{box_width}' height='#{box_height}' />\n"
            @extra_lines << rect
          end

          this_x += e[:width]
        end
      end
      @height = text_y if text_y != @height
    end
    bc[:height] = @height - bc[:y] + @connector_to_text * 2
    if element.brackets
      @extra_lines << generate_line(bc[:x], bc[:y], bc[:x] + @horizontal_spacing / 2, bc[:y], col)
      @extra_lines << generate_line(bc[:x], bc[:y], bc[:x], bc[:y] + bc[:height], col)
      @extra_lines << generate_line(bc[:x], bc[:y] + bc[:height], bc[:x] + @horizontal_spacing / 2, bc[:y] + bc[:height], col)
      @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width] - @horizontal_spacing / 2, bc[:y], col)
      @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width], bc[:y] + bc[:height], col)
      @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y] + bc[:height], bc[:x] + bc[:width] - @horizontal_spacing / 2, bc[:y] + bc[:height], col)
    end

    text = new_text
    @tree_data += text_data.sub(/CONTENT/, text)
  end

  def generate_line(x1, y1, x2, y2, col)
      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{FONT_SCALING}' />"
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

    line_data   = @line_styles.sub(/X1/, x1.to_s)
    line_data   = line_data.sub(/Y1/, y1.to_s)
    line_data   = line_data.sub(/X2/, x2.to_s)
    @tree_data += line_data.sub(/Y2/, y2.to_s)
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

    polygon_data = @polygon_styles.sub(/X1/, x1.to_s)
    polygon_data = polygon_data.sub(/Y1/, y1.to_s)
    polygon_data = polygon_data.sub(/X2/, x2.to_s)
    polygon_data = polygon_data.sub(/Y2/, y2.to_s)
    polygon_data = polygon_data.sub(/X3/, x3.to_s)
    @tree_data  += polygon_data.sub(/Y3/, y3.to_s)
  end
end
