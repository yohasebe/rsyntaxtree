# frozen_string_literal: true

#==========================
# graph.rb
#==========================
#
# Image utility functions to inspect text font metrics
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative 'utils'

module RSyntaxTree
  class BaseGraph
    def initialize(element_list, params, global)
      @global = global
      @element_list = element_list
      @symmetrize = params[:symmetrize]
      @direction = params[:direction] || "ttb"

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

      @col_line = if params[:hide_default_connectors] == true
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
        parent = @element_list.get_id(e.parent)
        e.level = @element_list.get_id(e.parent).level + 1 if parent
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

        if target.content_width > accum_width
          # Parent label is wider than children's total width.
          # Distribute the excess equally among children to prevent
          # child labels from overlapping when centered in their slots.
          excess = target.content_width - accum_width
          per_child = excess / target.children.size.to_f
          target.children.each do |c|
            child = @element_list.get_id(c)
            child.width += per_child
          end
          target.width = target.content_width
        else
          target.width = accum_width
        end
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
                            if @direction == "ltr"
                              # LTR: add small horizontal gap between parent and leaf
                              parent.vertical_indent + parent.content_height + @global[:height_connector_to_text]
                            else
                              parent.vertical_indent + parent.content_height
                            end
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
          if parent.triangle || child.contains_phrase
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "bar"
          if parent.triangle
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "nothing", "none"
          if parent.triangle
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

    # LTR layout: two-phase coordinate transformation.
    #
    # Phase 1 (before layout): swap content dimensions so the layout
    # algorithm uses text height for sibling spreading (→ vertical)
    # and text width for depth spacing (→ horizontal).
    def prepare_ltr
      @element_list.get_elements.each do |e|
        cw = e.content_width
        ch = e.content_height
        e.content_width = ch
        e.content_height = cw
      end

      # Save original global values for restoration in finalize_ltr
      @saved_h_gap = @global[:h_gap_between_nodes]
      @saved_height_connector = @global[:height_connector]

      # In LTR, siblings stack vertically. The TTB h_gap (char_width * 0.8)
      # is disproportionately large relative to the swapped content dimensions.
      # Use height_connector_to_text / 2 (= font_height / 4) for tight
      # vertical packing proportional to the font size.
      @global[:h_gap_between_nodes] = @global[:height_connector_to_text] / 2

      # In LTR, height_connector becomes horizontal depth between levels.
      # After content swap, content_height = original content_width (small),
      # so depth = small_value + height_connector. To maintain proportional
      # depth similar to TTB (where depth = content_height + height_connector),
      # compensate for the content dimension difference.
      metrics = @global[:single_x_metrics]
      content_diff = @global[:single_line_height] - metrics.width
      @global[:height_connector] = @global[:height_connector] + [content_diff, 0].max
    end

    # Phase 2 (after layout, before drawing): swap position axes
    # and restore original content dimensions for correct text rendering.
    def finalize_ltr
      @element_list.get_elements.each do |e|
        # Swap position axes
        h = e.horizontal_indent
        v = e.vertical_indent
        e.horizontal_indent = v
        e.vertical_indent = h

        # Restore original content dimensions (text is still horizontal)
        cw = e.content_width
        ch = e.content_height
        e.content_width = ch
        e.content_height = cw
      end

      # Restore original global values
      @global[:h_gap_between_nodes] = @saved_h_gap
      @global[:height_connector] = @saved_height_connector
    end

    def parse_list
      # Phase 1: swap content dimensions for LTR layout calculation
      prepare_ltr if @direction == "ltr"

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

      # Phase 2: swap axes and restore content dimensions for LTR
      finalize_ltr if @direction == "ltr"

      draw_elements
      draw_connector
      draw_paths

      # Calculate final bounds
      max_x = 0
      max_y = 0
      @element_list.get_elements.each do |e|
        r = e.horizontal_indent + e.content_width
        b = e.vertical_indent + e.content_height
        max_x = r if r > max_x
        max_y = b if b > max_y
      end
      width = max_x + @global[:h_gap_between_nodes]
      height = max_y
      height = @height if @height > height
      { height: height, width: width }
    end
  end
end
