#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# graph.rb
#==========================
#
# Image utility functions to inspect text font metrics
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require 'rmagick'
include Magick

class Graph

  def initialize(e_list, symmetrize, color, leafstyle, fontset, fontsize, vspace)

    # Store parameters
    @element_list  = e_list
    @leafstyle  = leafstyle
    @symmetrize = symmetrize
    @fontset = fontset
    @fontsize = fontsize

    # Initialize the image and colors
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

    @connector_to_text = 15
    @e_height = fontsize + @connector_to_text * 2
    standard = img_get_txt_metrics("X", @fontset[:normal], @fontsize, :normal, :normal)
    @vertical_spacing = standard.height * 1.1 * vspace
    @horizontal_spacing = standard.width * 0.75
  end

  def img_get_txt_metrics(text, font, fontsize, font_style, font_weight)
    background = Image.new(1, 1)
    gc = Draw.new
    gc.annotate(background, 0, 0, 0, 0, text) do |gc|
      gc.font = font
      gc.pointsize = fontsize
      gc.font_style = font_style == :italic ? ItalicStyle : NormalStyle
      gc.font_weight = font_weight == :bold ? BoldWeight : NormalWeight
      gc.gravity = CenterGravity
      gc.stroke = 'none'
      gc.kerning = 0
      gc.interline_spacing = 0
      gc.interword_spacing = 0
    end
    gc.get_multiline_type_metrics(background, text)
  end

  def calculate_level
    @element_list.get_elements.select{|e| e.type == 2}.each do |e|
      e.level = @element_list.get_id(e.parent).level + 1
    end
  end

  def calculate_width(id = 1)
    target = @element_list.get_id(id)
    if target.children.empty?
      target.width = target.content_width + @horizontal_spacing * 2
    else
      if target.width != 0
        return target.width
      else
        accum_array = []
        target.children.each do |c|
          accum_array << calculate_width(c)
        end
        if @symmetrize
          accum_width = accum_array.max * target.children.size
        else
          accum_width = accum_array.sum
        end

        target.width = [accum_width, target.content_width].max
      end
      return target.width
    end
  end

  def calculate_height(id = 1)
    target = @element_list.get_id(id)
    if id == 1
      target.vertical_indent = 0
    else
      parent = @element_list.get_id(target.parent)
      vertical_indent = parent.vertical_indent + parent.content_height + @vertical_spacing
      target.vertical_indent = vertical_indent
    end

    if target.children.empty?
      target.height = target.content_height
      vertical_end = target.vertical_indent + target.content_height
    else
      accum_array = []
      target.children.each do |c|
        accum_array << calculate_height(c)
      end
      target.height = accum_array.max - target.vertical_indent
      vertical_end = accum_array.max
    end
    return vertical_end
  end

  def make_balance(id = 1)
    target = @element_list.get_id(id)
    if target.children.empty?
      parent = @element_list.get_id(target.parent)
      accum_array = []
      parent.children.each do |c|
        accum_array << @element_list.get_id(c).width
      end
      max = accum_array.max
      parent.children.each do |c|
        @element_list.get_id(c).width = max
      end
      return max
    else
      accum_array = []
      target.children.each do |c|
        accum_array << make_balance(c)
      end
      accum_width = accum_array.max
      max = [accum_width, target.content_width].max
      target.children.each do |c|
        @element_list.get_id(c).width = max
      end
      return target.width
    end
  end

  def calculate_indent
    node_groups = @element_list.get_elements.group_by {|e| e.parent}
    node_groups.each do |k, v|
      next if k == 0
      parent = @element_list.get_id(k)
      if @symmetrize
        num_leaves = v.size
        partition_width = parent.width / num_leaves
        left_offset = parent.horizontal_indent + parent.content_width / 2.0 - parent.width / 2.0
        v.each do |e|
          indent = left_offset + (partition_width - e.content_width) / 2.0
          e.horizontal_indent = indent
          left_offset += partition_width
        end
      else
        left_offset = parent.horizontal_indent + parent.content_width / 2.0 - parent.width / 2.0
        v.each do |e|
          indent = left_offset + (e.width - e.content_width) / 2.0
          e.horizontal_indent = indent
          left_offset += e.width
        end
      end
    end
  end

  def draw_elements
    @element_list.get_elements.each do |element|
      draw_element(element)
    end
  end

  def draw_connector(id = 1)
    parent = @element_list.get_id(id)
    children = parent.children.map{|c| @element_list.get_id(c)}

    if children.empty?
      ;
    elsif children.size == 1
      child = children[0]
      if (@leafstyle == "auto" && ETYPE_LEAF == child.type)
        if child.contains_phrase || child.triangle
          triangle_to_parent(parent, child)
        else
          line_to_parent(parent, child)
        end
      elsif(@leafstyle == "bar" && ETYPE_LEAF == child.type)
        line_to_parent(parent, child)
      elsif(@leafstyle == "nothing")
        if ETYPE_LEAF == child.type
          child.vertical_indent = parent.vertical_indent + parent.content_height / 1.1
        end
      end
    else
      children.each do |child|
        line_to_parent(parent, child)
      end
    end

    parent.children.each do |c|
      draw_connector(c)
    end
  end

  def get_leftmost(id = 1)
    target = @element_list.get_id(id)
    target_indent = target.horizontal_indent
    children_indent = target.children.map{|c| get_leftmost(c)}
    (children_indent << target_indent).min
  end

  def get_rightmost(id = 1)
    target = @element_list.get_id(id)
    target_right_end = target.horizontal_indent + target.content_width
    children_right_end = target.children.map{|c| get_rightmost(c)}
    (children_right_end << target_right_end).max
  end

  def get_txt_only(text)
    text = text.strip
    if /\A([\+\-\=\*\#\~]+).+/ =~ text
      prefix = $1
      prefix_l = Regexp.escape(prefix)
      prefix_r = Regexp.escape(prefix.reverse)
      if /\A#{prefix_l}(.+)#{prefix_r}\z/ =~ text
        return $1
      end
    end
    return text
  end

  def node_centering
    node_groups = @element_list.get_elements.group_by {|e| e.parent}
    node_groups.sort_by{|k, v| -k}.each do |k, v|
      next if k == 0
      parent = @element_list.get_id(k)
      child_positions =v.map {|child| child.horizontal_indent + child.content_width / 2 }
      parent.horizontal_indent = child_positions.min + (child_positions.max - child_positions.min - parent.content_width) / 2
    end
  end

  def parse_list
    calculate_level
    calculate_width
    make_balance if @symmetrize
    calculate_indent
    node_centering

    top = @element_list.get_id(1)
    diff = top.horizontal_indent
    @element_list.get_elements.each do |e|
      e.horizontal_indent -= diff
    end

    offset_l = (top.horizontal_indent - get_leftmost) + @horizontal_spacing
    offset_r = top.width / 2 - offset_l - @horizontal_spacing

    @element_list.get_elements.each do |e|
      e.horizontal_indent += offset_l
    end

    calculate_height
    draw_connector
    draw_elements

    width = get_rightmost - get_leftmost + @horizontal_spacing * 2

    height = @element_list.get_id(1).height
    return {height: height, width: width}
  end
end
