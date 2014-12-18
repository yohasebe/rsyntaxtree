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
require 'elementlist'
# require 'rubygems'
require 'RMagick'
include Magick

E_WIDTH   = 60 # Element width
E_PADD    = 7 # Element height padding
V_SPACE   = 20
H_SPACE   = 10
B_SIDE   =   5
B_TOPBOT =   5

class TreeGraph

  def initialize(e_list, symmetrize = true, color = true, terminal = "auto",
                 font = "Helvetica", font_size = 10, simple = false)

    # Store parameters
    @e_list     = e_list
    @font       = font
    @font_size = font_size
    @terminal = terminal
    @symmetrize = symmetrize
    @simple = simple

    # Element dimensions
    @e_width   = E_WIDTH
    
    # Calculate image dimensions
    @e_height = @font_size + E_PADD * 2
    h = @e_list.get_level_height
    w = calc_level_width(0)
    w_px = w + B_SIDE * 2
    h_px = h * @e_height + (h-1) * (V_SPACE + @font_size) + B_TOPBOT * 2
    @height    = h_px
    @width     = w_px

    # Initialize the image and colors
    @im = Image.new(w_px, h_px)
    @gc = Draw.new
    @gc.font = @font
    @gc.pointsize(@font_size)

    @col_bg   = "none"
    @col_fg   = "black"
    @col_line = "black"
    
    if color
      @col_node  = "blue"
      @col_leaf  = "green"
      @col_trace = "red"
    else
      @col_node  = "black"
      @col_leaf  = "black"
      @col_trace = "black"
    end
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
    return @im.to_blob do
       self.format = fileformat
    end
  end  
  
  :private
 
  # Add the element into the tree (draw it)
  def draw_element(x, y, w, string, type)
    string = string.sub(/\^\z/){""} 
    # Calculate element dimensions and position
    if (type == ETYPE_LEAF) and @terminal == "nothing"
      top = row2px(y - 1) + (@font_size * 1.5)
    else 
      top   = row2px(y)
    end
    left   = x + B_SIDE
    bottom = top  + @e_height
    right  = left + w

    # Split the string into the main part and the 
    # subscript part of the element (if any)
    main = string
    sub  = ""

    sub_size = (@font_size * 0.7 )
    parts = string.split("_", 2)
  
    if(parts.length > 1 )
      main = parts[0]
      sub  = parts[1].gsub(/_/, " ")
    end
        
    # Calculate text size for the main and the 
    # subscript part of the element
    main_width = img_get_txt_width(main, @font, @font_size)

    if sub != ""
      sub_width  = img_get_txt_width(sub.to_s,  @font, sub_size)
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
    main_y = top + @e_height - E_PADD
    @gc.text(main_x.ceil, main_y.ceil, main)
        
    # Draw subscript text
    if (sub.length > 0 )
      @gc.pointsize(sub_size)
      sub_x = txt_pos + main_width + (sub_size/8)
      sub_y = top + (@e_height - E_PADD + sub_size / 2)
      @gc.text(sub_x.ceil, sub_y.ceil, sub)
    end
     
  end

  # Draw a line between child/parent elements
  def line_to_parent(fromX, fromY, fromW, toX, toW)

    if (fromY == 0 )
      return
    end
            
    fromTop  = row2px(fromY)
    fromLeft = (fromX + fromW / 2 + B_SIDE)
    toBot    = (row2px(fromY - 1 ) + @e_height)
    toLeft  = (toX + toW / 2 + B_SIDE)

    @gc.fill("none")
    @gc.stroke @col_line
    @gc.stroke_width 1
    @gc.line(fromLeft.ceil, fromTop.ceil, toLeft.ceil, toBot.ceil)
  end

  # Draw a triangle between child/parent elements
  def triangle_to_parent(fromX, fromY, fromW, toX, textW, symmetrize = true)
    if (fromY == 0)
      return
    end
      
    toX = fromX
    fromCenter = (fromX + fromW / 2 + B_SIDE)
    
    fromTop  = row2px(fromY).ceil
    fromLeft1 = (fromCenter + textW / 2).ceil
    fromLeft2 = (fromCenter - textW / 2).ceil
    toBot    = (row2px(fromY - 1) + @e_height)
    if symmetrize
      toLeft   = (toX + textW / 2 + B_SIDE)
    else
      toLeft   = (toX + textW / 2 + B_SIDE * 3)
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

  # Calculate the width of the element. If the element is
  #   a node, the calculation will be performed recursively
  #   for all child elements.
  def calc_element_width(e)
    w = 0
        
    children = @e_list.get_children(e.id)

    if(children.length == 0)
      w = img_get_txt_width(e.content, @font, @font_size) + @font_size
    else
      children.each do |child|
        child_e = @e_list.get_id(child)
        w += calc_element_width(child_e)
      end

      tw = img_get_txt_width(e.content, @font, @font_size) + @font_size
      if(tw > w)
        fix_child_size(e.id, w, tw)
        w = tw
      end
    end

    @e_list.set_element_width(e.id, w)
    return w
  end

  # Calculate the width of all elements in a certain level
  def calc_level_width(l)
    w = 0
    e = @e_list.get_first
    while e
      if(e.level == l)
        w += calc_element_width(e)
      end
        e = @e_list.get_next
    end

    return w
  end

  def calc_children_width(id)
    left = 0
    right = 0
    c_list = @e_list.get_children(id)
    return nil if c_list.empty?
    
    c_list.each do |c|
      left =  c.indent if indent == 0 or left > c.indent
    end
    c_list.each do |c|
      right = c.indent + e.width if c.indent + c.width > right
    end
    return [left, right]
  end

  def get_children_indent(id)
    calc_children_width(id)[0]
  end
  
  def get_children_width(id)
    calc_children_width(id)[1] - get_children_indent(id)
  end

  # Parse the elements in the list top to bottom and
  #   draw the elements into the image.
  #   As we it iterate through the levels, the element
  #   indentation is calculated.
  def parse_list

    # Calc element list recursively....
    e_arr = @e_list.get_elements
     
    h = @e_list.get_level_height
    h.times do |i|
      x = 0
      e_arr.each do |j|

        if (j.level == i)
          cw = @e_list.get_element_width(j.id)
          parent_indent = @e_list.get_indent(j.parent)
          if (x <  parent_indent)
            x = parent_indent
          end
          @e_list.set_indent(j.id, x)

          if !@symmetrize
            draw_element(x, i, cw, j.content, j.type)
            if(j.parent != 0 )
              words = j.content.split(" ")
              unless @terminal == "nothing" && ETYPE_LEAF == j.type
                if (@terminal == "triangle" && ETYPE_LEAF == j.type && x == parent_indent && words.length > 0)
                  txt_width = img_get_txt_width(j.content, @font, @font_size)
                  triangle_to_parent(x, i, cw, @e_list.get_element_width(j.parent), txt_width)
                elsif (@terminal == "auto" && ETYPE_LEAF == j.type && x == parent_indent)
                   if words.length > 1 || j.triangle
                     txt_width = img_get_txt_width(j.content, @font, @font_size)
                     triangle_to_parent(x, i, cw, @e_list.get_element_width(j.parent), txt_width, @symmetrize)
                   else
                     line_to_parent(x, i, cw, @e_list.get_indent(j.parent), @e_list.get_element_width(j.parent))
                   end
                else
                  line_to_parent(x, i, cw, @e_list.get_indent(j.parent), @e_list.get_element_width(j.parent))
                end
              end
            end
          end          

          x += cw
        end
      end
    end
    return true if !@symmetrize
    h.times do |i|
      curlevel = h - i - 1
      indent = 0
      e_arr.each_with_index do |j, idx|
        if (j.level == curlevel)
          # Draw a line to the parent element
          children = @e_list.get_children(j.id)

          tw = img_get_txt_width(j.content, @font, @font_size)
          if children.length > 1
            left, right = -1, -1
            children.each do |child|          
              k = @e_list.get_id(child)
              kw = img_get_txt_width(k.content, @font, @font_size)              
              left = k.indent + kw / 2 if k.indent + kw / 2 < left or left == -1
              right = k.indent + kw / 2 if k.indent + kw / 2 > right
            end
            draw_element(left, curlevel, right - left, j.content, j.type)
            @e_list.set_indent(j.id, left + (right - left) / 2 -  tw / 2)

            children.each do |child|
              k = @e_list.get_id(child)
              words = k.content.split(" ")
              dw = img_get_txt_width(k.content, @font, @font_size)
              unless @terminal == "nothing" && ETYPE_LEAF == k.type
                if (@terminal == "triangle" && ETYPE_LEAF == k.type && k.indent == j.indent && words.length > 0)
                  txt_width = img_get_txt_width(k.content, @font, @font_size)
                  triangle_to_parent(k.indent, curlevel + 1, dw, tw, txt_width)
                elsif (@terminal == "auto" && ETYPE_LEAF == k.type && k.indent == j.indent)
                  if words.length > 1 || k.triangle
                    txt_width = img_get_txt_width(k.content, @font, @font_size)
                    triangle_to_parent(k.indent, curlevel + 1, dw, tw, txt_width)
                  else
                    line_to_parent(k.indent, curlevel + 1, dw, j.indent, tw)
                  end
                else
                  line_to_parent(k.indent, curlevel + 1, dw, j.indent, tw)
                end
              end
            end
            
          else
            unless children.empty?
              k = @e_list.get_id(children[0])
              kw = img_get_txt_width(k.content, @font, @font_size)              
              left = k.indent
              right = k.indent + kw
              draw_element(left, curlevel, right - left, j.content, j.type)
              @e_list.set_indent(j.id, left + (right - left) / 2 -  tw / 2)
            else
             parent = @e_list.get_id(j.parent)
             pw = img_get_txt_width(parent.content, @font, @font_size)
             pleft = parent.indent
             pright = pleft + pw
             left = j.indent
             right = left + tw
             if pw > tw
               left = pleft
               right = pright
             end
             draw_element(left, curlevel, right - left, j.content, j.type) 
             @e_list.set_indent(j.id, left + (right - left) / 2 -  tw / 2)             
            end

            unless children.empty?
              k = @e_list.get_id(children[0])
              words = k.content.split(" ")
              dw = img_get_txt_width(k.content, @font, @font_size)
              unless @terminal == "nothing" && ETYPE_LEAF == k.type
                if (@terminal == "triangle" && ETYPE_LEAF == k.type && words.length > 0)
                  txt_width = img_get_txt_width(k.content, @font, @font_size)
                  triangle_to_parent(k.indent, curlevel + 1, dw, 
                                     @e_list.get_element_width(k.parent), txt_width)
                elsif (@terminal == "auto" && ETYPE_LEAF == k.type)
                  if words.length > 1 || k.triangle
                    txt_width = img_get_txt_width(k.content, @font, @font_size)
                    triangle_to_parent(k.indent, curlevel + 1, dw, @e_list.get_element_width(k.parent), txt_width)
                  else
                    line_to_parent(k.indent, curlevel + 1, dw, j.indent, tw)
                  end
                else
                  line_to_parent(k.indent, curlevel + 1, dw, j.indent, tw)
                end
              end
            end
          end
        end
      end
    end
  end

  def row2px(row)
   B_TOPBOT + @e_height * row + (V_SPACE + @font_size) * row
  end
  
end
