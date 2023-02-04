# frozen_string_literal: true

#==========================
# graph.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2023 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative 'utils'

module RSyntaxTree
  class BaseGraph
    def initialize(element_list, params, global)
      @global = global
      @element_list = element_list
      @symmetrize = params[:symmetrize]

      case params[:color]
      # Okabe-Ito Color
      when "modern"
        @col_node = "#0072B2" # blue
        @col_leaf = "#009E73" # bluishgreen
        @col_path = "#CC79A7" # reddishpurple
        @col_extra = "#CC79A7" # orange
        @col_emph = "#D55E00" # vermillion
        # "#000000" black
        # "#56B4E9" skyblue
        # "#F0E442" yellow
        # "#999999" grey
      when "traditional"
        @col_node  = "blue"
        @col_leaf  = "green"
        @col_path = "purple"
        @col_extra = "purple"
        @col_emph = "red"
      else
        @col_node  = "black"
        @col_leaf  = "black"
        @col_path = "black"
        @col_extra = "black"
      end

      @col_bg   = "none"
      @col_fg   = "black"

      @col_line = if params[:hide_default_connectors]
                    "none"
                  else
                    "black"
                  end

      @leafstyle = params[:leafstyle]
      @fontset = params[:fontset]
      @fontsize = params[:fontsize]
    end

    def calculate_level
      @element_list.get_elements.select { |e| e.type == 2 }.each do |e|
        e.level = @element_list.get_id(e.parent).level + 1
      end
    end

    def calculate_width(id = 1)
      target = @element_list.get_id(id)
      if target.children.empty?
        target.width = target.content_width + @global[:h_gap_between_nodes] * 4

        parent = @element_list.get_id(target.parent)
        while parent && parent.children.size == 1
          w = parent.content_width
          target.width = w + @global[:h_gap_between_nodes] * 4 if w > target.content_width
          parent = @element_list.get_id(parent.parent)
        end
        target.width
      else
        return target.width if target.width != 0

        accum_array = []
        target.children.each do |c|
          accum_array << calculate_width(c)
        end
        accum_width = if @symmetrize
                        accum_array.max * target.children.size
                      else
                        accum_array.sum
                      end

        target.width = [accum_width, target.content_width].max
      end
    end

    def calculate_height(id = 1)
      target = @element_list.get_id(id)
      if id == 1
        target.vertical_indent = 0
      else
        parent = @element_list.get_id(target.parent)

        vertical_indent = if !target.triangle &&
                             (@leafstyle == "nothing" || @leafstyle == "none") &&
                             ETYPE_LEAF == target.type && parent.children.size == 1
                            parent.vertical_indent + parent.content_height
                          else
                            parent.vertical_indent + parent.content_height + @global[:height_connector]
                          end
        target.vertical_indent = vertical_indent
      end

      if target.children.empty?
        target.height = target.content_height
        target.vertical_indent + target.content_height
      else
        accum_array = []
        target.children.each do |c|
          accum_array << calculate_height(c)
        end
        target.height = accum_array.max - target.vertical_indent
        accum_array.max
      end
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
        max
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
        target.width
      end
    end

    def calculate_indent
      node_groups = @element_list.get_elements.group_by(&:parent)
      node_groups.each do |k, v|
        next if k.zero?

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
      children = parent.children.map { |c| @element_list.get_id(c) }

      if children.size == 1
        child = children[0]
        case @leafstyle
        when "auto"
          if child.contains_phrase || child.triangle
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "bar"
          if child.triangle
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "nothing", "none"
          if child.triangle
            triangle_to_parent(parent, child)
          elsif ETYPE_LEAF != child.type
            line_to_parent(parent, child)
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
      children_indent = target.children.map { |c| get_leftmost(c) }
      (children_indent << target_indent).min
    end

    def get_rightmost(id = 1)
      target = @element_list.get_id(id)
      target_right_end = target.horizontal_indent + target.content_width
      children_right_end = target.children.map { |c| get_rightmost(c) }
      (children_right_end << target_right_end).max
    end

    def node_centering
      node_groups = @element_list.get_elements.group_by(&:parent)
      node_groups.sort_by { |k, _v| -k }.each do |k, v|
        next if k.zero?

        parent = @element_list.get_id(k)
        child_positions = v.map { |child| child.horizontal_indent + child.content_width / 2 }
        parent.horizontal_indent = child_positions.min + (child_positions.max - child_positions.min - parent.content_width) / 2
      end
    end

    def parse_list
      if @element_list.elements.size > 1
        calculate_level
        calculate_width
        make_balance if @symmetrize
        calculate_indent
        node_centering
      end

      top = @element_list.get_id(1)
      diff = top.horizontal_indent
      @element_list.get_elements.each do |e|
        e.horizontal_indent -= diff
      end

      offset_l = (top.horizontal_indent - get_leftmost) + @global[:h_gap_between_nodes]

      @element_list.get_elements.each do |e|
        e.horizontal_indent += offset_l
      end

      calculate_height
      draw_elements
      draw_connector
      draw_paths

      width = get_rightmost - get_leftmost + @global[:h_gap_between_nodes]
      height = @element_list.get_id(1).height
      height = @height if @height > height
      { height: height, width: width }
    end
  end
end
