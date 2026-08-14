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
      @mirror = params[:mirror] == true
      @tidy = params[:tidy] == true
      @tidy_spacing = params[:tidy_spacing] || 1.0
      @tidy_slope = params[:tidy_slope] || 0.3
      # Tidy mode bundles the dynamic connector height: contour compression
      # pulls sibling subtrees together, and the dynamic drop keeps branch
      # angles even as the horizontal spread shrinks.
      @dynamic_connector = @tidy
      # Symmetrize (uniform sibling slots) and tidy (contour packing) pursue
      # contradictory layouts; combining them is meaningless, so tidy wins
      # and symmetrize is silently ignored when both are on.
      @symmetrize = false if @tidy
    end

    # Vertical drop for the connectors descending from +parent+.
    #
    # With a fixed drop, branch angles differ sharply between nodes whose
    # children sit close together (deep in a binary tree) and nodes whose
    # children are far apart (near the root, where the branches flatten out).
    # When tidy mode is on, the drop grows with the horizontal spread of the
    # children (slope: tidy_slope) so the branches keep a similar slope
    # throughout the tree. The growth is capped; the cap scales with the
    # slope (2.5x at the default slope) so that lowering the slope also
    # lowers the maximum drop — one knob controls "too tall" trees.
    def connector_height_for(parent)
      base = @global[:height_connector]
      return base unless @dynamic_connector

      # Use the same drop for every parent on a level (the level's widest
      # spread). Per-parent drops leave same-depth cousins at slightly
      # different heights, which reads as misaligned rows.
      level_connector_heights[parent.level] || base
    end

    def raw_connector_height_for(parent)
      base = @global[:height_connector]
      children = parent.children.map { |c| @element_list.get_id(c) }.compact
      return base if children.size < 2

      centers = children.map { |c| c.horizontal_indent + c.content_width / 2.0 }
      spread = centers.max - centers.min
      return base if spread <= 0

      cap = base * [1.0, 2.5 * @tidy_slope / 0.3].max
      [[spread * @tidy_slope, base].max, cap].min
    end

    def level_connector_heights
      @level_connector_heights ||= @element_list.get_elements.each_with_object({}) do |e, drops|
        next if e.children.empty?

        h = raw_connector_height_for(e)
        drops[e.level] = [drops[e.level] || 0, h].max
      end
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
        # Drops depend on the current horizontal layout, which changes
        # between tidy passes — recompute them for each full pass.
        @level_connector_heights = nil
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
                            parent.vertical_indent + parent.content_height + connector_height_for(parent)
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

    # Flip the laid-out tree horizontally (RTL linguistics convention: the
    # first word sits at the right edge). Connectors, triangles, polylines,
    # movement paths, and region shades all derive from element coordinates,
    # so flipping every element here keeps them consistent. Works for both
    # directions: ttb yields a right-to-left vertical tree; ltr puts the
    # root at the right edge of the horizontal tree.
    def mirror_layout
      max_right = @element_list.get_elements.map { |e| e.horizontal_indent + e.content_width }.max
      @element_list.get_elements.each do |e|
        e.horizontal_indent = max_right - (e.horizontal_indent + e.content_width)
      end
      # Re-align the left edge to the standard left margin
      offset = @global[:h_gap_between_nodes] - get_leftmost
      @element_list.get_elements.each { |e| e.horizontal_indent += offset }
    end

    # --- Tidy mode: Reingold-Tilford-style contour compression ---

    # Compression passes alternate with height recalculation until the
    # layout stops moving (the dynamic connector height couples y to the
    # horizontal spread, so the two must settle together). The cap only
    # guards against pathological oscillation.
    TIDY_MAX_ITERATIONS = 10
    TIDY_CONVERGENCE = 0.5 # px; a pass shifting less than this is stable

    # Base multiplier for the minimum clearance between adjacent subtrees.
    # At 1.0 (= raw h_gap_between_nodes) leaf labels sit closer than in the
    # standard layout, which reads as crowded; 2.5 restores comparable air
    # while keeping a good part of the compression.
    TIDY_BASE_SPACING = 2.5

    # Minimum horizontal clearance kept between adjacent subtrees.
    # tidy_spacing scales the default gap (1.0 = default).
    def tidy_gap
      @global[:h_gap_between_nodes] * TIDY_BASE_SPACING * @tidy_spacing
    end

    # Effective visual rectangle of +node+ as [y0, y1, x0, x1], widening the
    # content rect where the drawing extends beyond it. Mirrors the geometry
    # of SVGGraph#element_visual_box: enclosures (#/##/###) paint brackets or
    # a rectangle outside the label, so the contour must reserve that space.
    # Triangles need no widening (their base spans exactly the child's
    # content width). Vertically the full content box is kept — a
    # conservative superset of the glyph box, which is what the horizontal
    # contour comparison needs.
    def effective_rect(node)
      x0 = node.horizontal_indent
      x1 = node.horizontal_indent + node.content_width
      if [:brackets, :rectangle, :brectangle].include?(node.enclosure)
        ext = @global[:h_gap_between_nodes] / 2 + ((@linewidth || 1) + BLINE_SCALING)
        x0 -= ext
        x1 += ext
      end
      [node.vertical_indent, node.vertical_indent + node.content_height, x0, x1]
    end

    # Effective-rect list of the subtree rooted at +id+, as [y0, y1, x0, x1].
    # A region-shaded (%) node additionally contributes the shade's padded
    # bounding rect so that neighboring subtrees keep clear of the plane.
    def subtree_rects(id)
      node = @element_list.get_id(id)
      rects = [effective_rect(node)]
      node.children.each { |c| rects.concat(subtree_rects(c)) }
      if node.region
        pad = @global[:h_gap_between_nodes]
        rects << [rects.map { |r| r[0] }.min - pad / 2.0,
                  rects.map { |r| r[1] }.max + pad,
                  rects.map { |r| r[2] }.min - pad,
                  rects.map { |r| r[3] }.max + pad]
      end
      rects
    end

    # [left edge of the leftmost leaf, right edge of the rightmost leaf] of
    # the subtree rooted at +id+ (effective extents), or nil when the
    # subtree has no leaf (cannot happen in practice — every subtree ends
    # in leaves).
    def subtree_leaf_span(id)
      leaves = []
      stack = [@element_list.get_id(id)]
      until stack.empty?
        node = stack.pop
        if node.children.empty?
          leaves << node
        else
          node.children.each { |c| stack << @element_list.get_id(c) }
        end
      end
      return nil if leaves.empty?

      rects = leaves.map { |e| effective_rect(e) }
      [rects.map { |r| r[2] }.min, rects.map { |r| r[3] }.max]
    end

    # Minimum horizontal clearance between two sets of rects over the y
    # intervals where both sets have coverage; nil when they never co-occur
    # in y. Exact: within an elementary y interval the covering rects are
    # constant, so comparing the max right edge against the min left edge
    # gives the worst point of that interval.
    def contour_clearance(left_rects, right_rects)
      boundaries = (left_rects + right_rects).flat_map { |r| [r[0], r[1]] }.uniq.sort
      clearance = Float::INFINITY
      boundaries.each_cons(2) do |y0, y1|
        left = left_rects.select { |r| r[0] < y1 && r[1] > y0 }
        right = right_rects.select { |r| r[0] < y1 && r[1] > y0 }
        next if left.empty? || right.empty?

        gap = right.map { |r| r[2] }.min - left.map { |r| r[3] }.max
        clearance = gap if gap < clearance
      end
      clearance.infinite? ? nil : clearance
    end

    def shift_subtree(id, delta)
      node = @element_list.get_id(id)
      node.horizontal_indent += delta
      node.children.each { |c| shift_subtree(c, delta) }
    end

    # One compression pass. For each internal node (deepest first), adjacent
    # child subtrees are pulled together until (a) their contours clear each
    # other by tidy_gap and (b) the leftmost leaf of the right subtree stays
    # right of the rightmost leaf of the left subtree — (b) keeps the global
    # leaf order intact even where the two subtrees never share a y band
    # (contours alone cannot see that case). A negative clearance (possible
    # when the previous height recalculation raised nodes into a shared y
    # band) pushes the right subtree back out — the dynamic connector height
    # couples y to the horizontal spread, so passes must run in both
    # directions to reach a fixpoint. Moving the right subtree only ever
    # drives the gap to its left neighbor toward the constraints and grows
    # the gap to its right neighbor, so a single left-to-right sweep per
    # parent cannot create new collisions; non-adjacent subtrees stay
    # separated transitively. The parent is then re-centered over its
    # children (node_centering rule).
    #
    # Returns the largest absolute shift applied (for convergence testing).
    def tidy_compress
      max_shift = 0.0
      parents = @element_list.get_elements.reject { |e| e.children.empty? }
      parents.sort_by { |p| [-p.level, -p.id] }.each do |parent|
        children = parent.children.map { |c| @element_list.get_id(c) }
        children.each_cons(2) do |left_child, right_child|
          clearance = contour_clearance(subtree_rects(left_child.id), subtree_rects(right_child.id))
          delta = clearance.nil? ? 0.0 : tidy_gap - clearance

          left_span = subtree_leaf_span(left_child.id)
          right_span = subtree_leaf_span(right_child.id)
          if left_span && right_span
            leaf_delta = left_span[1] + tidy_gap - right_span[0]
            delta = leaf_delta if leaf_delta > delta
          end
          next if delta.abs < 0.01

          shift_subtree(right_child.id, delta)
          max_shift = delta.abs if delta.abs > max_shift
        end
        centers = children.map { |c| c.horizontal_indent + c.content_width / 2.0 }
        parent.horizontal_indent = centers.min + (centers.max - centers.min - parent.content_width) / 2
      end
      max_shift
    end

    # Shift the whole tree so the leftmost node lands one gap from the edge.
    def normalize_horizontal
      offset = @global[:h_gap_between_nodes] - get_leftmost
      @element_list.get_elements.each { |e| e.horizontal_indent += offset }
    end

    # Snapshot / restore of everything the tidy passes mutate.
    def layout_snapshot
      @element_list.get_elements.map { |e| [e.horizontal_indent, e.vertical_indent, e.height] }
    end

    def restore_layout(snapshot)
      @element_list.get_elements.zip(snapshot) do |e, (h, v, ht)|
        e.horizontal_indent = h
        e.vertical_indent = v
        e.height = ht
      end
    end

    # Pairwise intersection over the effective (decoration-aware) rects.
    def layout_overlaps?
      rects = @element_list.get_elements.map { |e| effective_rect(e) }
      rects.combination(2).any? do |a, b|
        a[2] < b[3] - 0.01 && b[2] < a[3] - 0.01 && a[0] < b[1] - 0.01 && b[0] < a[1] - 0.01
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

      # Tidy mode: compress sibling subtrees by their contours, then let the
      # dynamic connector height settle. Each pass compresses against the
      # current vertical layout and recomputes heights for the next one;
      # repeat until neither moves (see tidy_compress for why passes must
      # also be able to push subtrees back apart). For LTR this runs in the
      # swapped coordinate system, where the same logic applies.
      #
      # Safety net: convergence is not proven, and a height recalculation
      # can transiently move nodes into a shared y band (which the NEXT
      # pass repairs by pushing subtrees apart). So passes are allowed to
      # continue through transient overlaps, but the last overlap-free
      # state is always remembered, and any overlapping final state is
      # rolled back to it — tidy never emits an overlapping tree.
      if @tidy && @element_list.elements.size > 1
        snapshot = layout_snapshot # the pre-tidy layout is overlap-free
        TIDY_MAX_ITERATIONS.times do
          max_shift = tidy_compress
          normalize_horizontal
          calculate_height
          next if layout_overlaps?

          snapshot = layout_snapshot
          break if max_shift < TIDY_CONVERGENCE
        end
        restore_layout(snapshot) if layout_overlaps?
      end

      # Phase 2: swap axes and restore content dimensions for LTR
      finalize_ltr if @direction == "ltr"

      # RTL flip (mirror option): after the layout is final, before drawing
      mirror_layout if @mirror

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
