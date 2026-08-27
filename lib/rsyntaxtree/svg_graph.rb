# frozen_string_literal: true

#==========================
# svg_graph.rb
#==========================
#
# Parses an element list into an SVG tree.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

# No tempfile usage in this file
require_relative 'base_graph'
require_relative 'utils'

module RSyntaxTree
  class SVGGraph < BaseGraph
    # Default color for a region shade drawn with bare '%' (no color spec).
    # An explicit '%@color:' is always honored, even in color-off mode, to
    # stay consistent with how the @color: node-text color behaves.
    REGION_DEFAULT_COLOR = "#888888"
    # Fill opacity for region shades; low enough that nested/overlapping
    # shades stack naturally without obscuring the tree underneath.
    REGION_FILL_OPACITY = 0.2
    # The border reuses the fill color but at a higher opacity, so it reads as
    # a darker shade of the same color — keeping the region clearly bounded on
    # a white page without a per-color "darker shade" lookup.
    REGION_STROKE_OPACITY = 0.55

    attr_accessor :width, :height

    def initialize(element_list, params, global)
      super(element_list, params, global)
      @height = 0
      @width  = 0
      @extra_lines = []
      @region_shades = []
      @fontset = params[:fontset]
      @fontsize = params[:fontsize]
      @linewidth = params[:linewidth]
      @transparent = params[:transparent] == true
      @color = params[:color]
      @fontstyle = params[:fontstyle]
      @polyline = params[:polyline] == true
      @direction = params[:direction] || "ttb"
      @line_styles = "<line style='fill: none; stroke:#{@col_line}; stroke-width:#{@global[:stroke_normal]}; stroke-linejoin:round; stroke-linecap:round;' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
      @polyline_styles = "<polyline style='stroke:#{@col_line}; stroke-width:#{@global[:stroke_normal]}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='CHIX CHIY MIDX1 MIDY1 MIDX2 MIDY2 PARX PARY' />\n"
      @polygon_styles = "<polygon style='fill: none; stroke: #{@col_connector}; stroke-width:#{@global[:stroke_normal]}; stroke-linejoin:round;stroke-linecap:round;' points='X1 Y1 X2 Y2 X3 Y3' />\n"
      @text_styles = "<text white-space='pre' alignment-baseline='text-top' style='fill: COLOR; storoke-width: 0; font-size: fontsize' x='X_VALUE' y='Y_VALUE'>CONTENT</text>\n"
      @tree_data = String.new
      @visited_x = {}
      @visited_y = {}
      @global = global
    end

    def svg_data
      metrics = parse_list

      # Region shades depend on the final element positions and on the node
      # content_height that draw_element recomputes, so collect them only
      # after parse_list (which runs draw_elements) has completed.
      collect_region_shades

      @width = metrics[:width] + @global[:h_gap_between_nodes] * 2
      @height = metrics[:height] + @global[:height_connector_to_text] / 2

      x1 = 0 - @global[:h_gap_between_nodes]
      y1 = 0
      x2 = @width + @global[:h_gap_between_nodes]
      y2 = @height + @global[:height_connector_to_text] / 2

      # Grow the canvas so region shades that reach past the tree's own bounds
      # (e.g. a region on the root node, or one whose padded edge extends beyond
      # the deepest leaf) keep a margin instead of touching the image edge. A
      # margin is added around the region extents before unioning with the tree
      # bounds. x2/y2 are the viewBox width/height, so right = x1 + x2.
      if @region_bounds
        rb = @region_bounds
        m = @global[:h_gap_between_nodes]
        left = [x1, rb[:min_x] - m].min
        top = [y1, rb[:min_y] - m].min
        right = [x1 + x2, rb[:max_x] + m].max
        bottom = [y1 + y2, rb[:max_y] + m].max
        new_x2 = right - left
        new_y2 = bottom - top
        @width += new_x2 - x2
        @height += new_y2 - y2
        x1 = left
        y1 = top
        x2 = new_x2
        y2 = new_y2
      end

      extra_lines = @extra_lines.join("\n")

      as2 = @global[:h_gap_between_nodes] * 1.0
      as4 = as2 * 3
      # The hatch density follows the type size the way the enclosure it
      # fills does: the cell is 10/32 of the font size, the line 4/32 —
      # the ratios the absolute 10 and 4 had at the default size.
      hatch_cell = @fontsize * 0.3125
      hatch_stroke = @fontsize * 0.125

      header = <<~HDR
        <?xml version="1.0" standalone="no"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
          <svg width="#{x2}" height="#{y2}" viewBox="#{x1}, #{y1}, #{x2}, #{y2}" version="1.1" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <marker id="arrow" markerUnits="userSpaceOnUse" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="#{as2}" markerHeight="#{as2}" orient="auto">
              <path d="M 0 0 L 10 5 L 0 10" fill="#{@col_extra}"/>
            </marker>
            <marker id="arrowStart" markerUnits="userSpaceOnUse" viewBox="0 0 10 10" refX="0" refY="5" markerWidth="#{as2}" markerHeight="#{as2}" orient="auto">
              <path d="M 10 0 L 0 5 L 10 10" fill="#{@col_extra}"/>
            </marker>
            <marker id="arrowBackward" markerUnits="userSpaceOnUse" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="#{as2}" markerHeight="#{as2}" orient="auto">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="#{@col_extra}"/>
            </marker>
            <marker id="arrowForward" markerUnits="userSpaceOnUse" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="#{as2}" markerHeight="#{as2}" orient="auto">
              <path d="M 10 0 L 0 5 L 10 10 z" fill="#{@col_extra}"/>
            </marker>
            <marker id="arrowBothways" markerUnits="userSpaceOnUse" viewBox="0 0 30 10" refX="15" refY="5" markerWidth="#{as4}" markerHeight="#{as2}" orient="auto">
              <path d="M 0 5 L 10 0 L 10 5 L 20 5 L 20 0 L 30 5 L 20 10 L 20 5 L 10 5 L 10 10 z" fill="#{@col_extra}"/>
            </marker>
            <pattern id="hatchBlack" x="10" y="10" width="#{hatch_cell}" height="#{hatch_cell}" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="#{hatch_cell}" stroke="black" stroke-width="#{hatch_stroke}"></line>
            </pattern>
            <pattern id="hatchForNode" x="10" y="10" width="#{hatch_cell}" height="#{hatch_cell}" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="#{hatch_cell}" stroke="#{@col_node}" stroke-width="#{hatch_stroke}"></line>
            </pattern>
            <pattern id="hatchForLeaf" x="10" y="10" width="#{hatch_cell}" height="#{hatch_cell}" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="#{hatch_cell}" stroke="#{@col_leaf}" stroke-width="#{hatch_stroke}"></line>
            </pattern>
          </defs>
      HDR

      rect = <<~RCT
        <rect x="#{x1}" y="#{y1}" width="#{x2}" height="#{y2}" stroke="none" fill="white" />
      RCT

      footer = "</svg>"

      # Region shades go at the very back: above the white background but
      # below tree connectors and labels.
      shades = @region_shades.join

      if @transparent
        header + shades + @tree_data + extra_lines + footer
      else
        header + rect + shades + @tree_data + extra_lines + footer
      end
    end

    # Collect a background rectangle for every element flagged with '%'.
    # Outer (shallower) regions are emitted first so deeper ones layer on
    # top; with low opacity the overlap reads as a darker nesting.
    def collect_region_shades
      hctt = @global[:height_connector_to_text]
      pad = @global[:h_gap_between_nodes]  # generous padding for the non-parent-facing edges
      pad_parent = hctt / 2.0              # tighter margin on the parent-facing edge of the root
      radius = hctt / 2.0
      stroke_width = @global[:stroke_normal]
      half = stroke_width / 2.0
      @element_list.get_elements.each do |element|
        next unless element.region

        b = region_subtree_bounds(element.id)
        left = b[:left] - pad
        right = b[:right] + pad
        top = b[:top] - pad
        bottom = b[:bottom] + pad

        # The edge facing the parent is handled specially so the incoming
        # connector neither overlaps nor touches the plane. That edge is the
        # TOP in top-to-bottom layout and the LEFT in left-to-right layout; the
        # other edges keep the generous padding. For a non-root node the edge
        # is placed midway between the connector anchor and the content edge
        # (even gap on both sides); the tree root has no incoming connector, so
        # it just gets a tighter-but-consistent margin there.
        is_root = element.parent.zero?
        if @direction == "ltr"
          anchor = element.horizontal_indent - hctt
          left = if is_root
                   b[:left] - pad_parent
                 elsif anchor < b[:left]
                   (b[:left] + anchor) / 2.0
                 else
                   left
                 end
        else
          anchor = element.vertical_indent + hctt / 2.0
          top = if is_root
                  b[:top] - pad_parent
                elsif anchor < b[:top]
                  (b[:top] + anchor) / 2.0
                else
                  top
                end
        end

        x = left
        y = top
        w = right - left
        h = bottom - top
        # An explicit shade color is always honored (consistent with the
        # @color: node-text color); bare '%' falls back to gray.
        color = element.region_color || REGION_DEFAULT_COLOR
        @region_shades << "<rect x='#{x}' y='#{y}' width='#{w}' height='#{h}' rx='#{radius}' ry='#{radius}' " \
                          "fill='#{color}' fill-opacity='#{REGION_FILL_OPACITY}' " \
                          "stroke='#{color}' stroke-opacity='#{REGION_STROKE_OPACITY}' stroke-width='#{stroke_width}' />\n"

        # Track the union of region extents (the stroke straddles the edge, so
        # it reaches half a stroke-width outside the rect) for canvas growth.
        rb = (@region_bounds ||= { min_x: x - half, min_y: y - half, max_x: x + w + half, max_y: y + h + half })
        rb[:min_x] = x - half if x - half < rb[:min_x]
        rb[:min_y] = y - half if y - half < rb[:min_y]
        rb[:max_x] = x + w + half if x + w + half > rb[:max_x]
        rb[:max_y] = y + h + half if y + h + half > rb[:max_y]
      end
    end

    # Visual bounding box of a single element as actually drawn: the label /
    # enclosure box (which starts hctt*3/4 below vertical_indent, i.e. below the
    # connector gap) widened to include any enclosure bracket/rectangle that is
    # painted beyond the content width.
    def element_visual_box(el)
      hctt = @global[:height_connector_to_text]
      box_top = el.vertical_indent + hctt * 3 / 4 # bc[:y]: line-height / enclosure box top
      box_bottom = box_top + el.content_height
      left = el.horizontal_indent
      right = el.horizontal_indent + el.content_width
      if [:brackets, :rectangle, :brectangle].include?(el.enclosure)
        # The room the enclosure needs is already part of content_width; only
        # the stroke straddling the edge reaches beyond it.
        ext = @global[:stroke_bold]
        left -= ext
        right += ext
        sw = @global[:stroke_bold]
        top = box_top - sw
        bottom = box_bottom + sw
      else
        # No enclosure box is painted, so hug the actual glyphs rather than the
        # taller line-height box: the line box carries ~hctt*3/4 of leading both
        # above the cap top and below the baseline, which would otherwise leave
        # too much empty space above and below a plain label.
        top = el.vertical_indent + hctt * 3 / 2
        bottom = box_bottom - hctt * 3 / 4
      end
      { left: left, top: top, right: right, bottom: bottom }
    end

    # Union of element_visual_box over the subtree rooted at +id+, in final
    # drawing coordinates. Used to size region shades so the whole subtree
    # (labels, enclosures, brackets) sits inside the plane.
    def region_subtree_bounds(id)
      b = element_visual_box(@element_list.get_id(id))
      @element_list.get_id(id).children.each do |c|
        cb = region_subtree_bounds(c)
        b[:left] = cb[:left] if cb[:left] < b[:left]
        b[:right] = cb[:right] if cb[:right] > b[:right]
        b[:top] = cb[:top] if cb[:top] < b[:top]
        b[:bottom] = cb[:bottom] if cb[:bottom] > b[:bottom]
      end
      b
    end

    # A point the given distance from `from` along the line towards `to`.
    def along(from, to, distance)
      dx = to[0] - from[0]
      dy = to[1] - from[1]
      length = Math.sqrt((dx * dx) + (dy * dy))
      return from.dup if length.zero?

      [from[0] + (dx / length * distance), from[1] + (dy / length * distance)]
    end

    # The `d` of a polyline whose corners are eased into quarter turns.
    #
    # The radius is clamped to half of each of the two runs meeting at a corner,
    # so a short leg can never be swallowed by its own turn and two adjacent
    # corners can never overlap — which is the whole of the arithmetic that
    # rounding a right angle needs, and why it can be a constant everywhere
    # else.
    def rounded_polyline_d(points, radius)
      return +"" if points.size < 2

      at = ->(p) { "#{p[0].round(3)},#{p[1].round(3)}" }
      d = +"M#{at.call(points[0])}"
      points.each_cons(3) do |before, corner, after|
        r = [radius,
             Math.sqrt(((corner[0] - before[0])**2) + ((corner[1] - before[1])**2)) / 2.0,
             Math.sqrt(((after[0] - corner[0])**2) + ((after[1] - corner[1])**2)) / 2.0].min
        if r < 0.01
          d << " L#{at.call(corner)}"
        else
          d << " L#{at.call(along(corner, before, r))}" \
               " Q#{at.call(corner)} #{at.call(along(corner, after, r))}"
        end
      end
      d << " L#{at.call(points.last)}"
    end

    # One stroke rather than three lines meeting at right angles. Drawn this way
    # the dash pattern runs round each turn instead of restarting at it, and an
    # arrowhead is the end of the stroke rather than a marker on whichever line
    # happens to finish last.
    def generate_path(points, col, dashed: false, radius: 0, start_arrow: false, end_arrow: false)
      # An arrowhead is drawn back along the run it ends, so the corner before
      # it has to leave that run its full length. Without this the shorter of
      # the two end runs — which is only as long as the path's bulge — lost half
      # of itself to the turn and the head came out sitting on the curve.
      arrow_length = @global[:h_gap_between_nodes]
      leg = ->(a, b) { Math.sqrt(((a[0] - b[0])**2) + ((a[1] - b[1])**2)) }
      radius = [radius, leg.call(points[0], points[1]) - arrow_length].min if start_arrow
      radius = [radius, leg.call(points[-2], points[-1]) - arrow_length].min if end_arrow
      radius = [radius, 0].max

      dash = @fontsize / 4.0
      dasharray = dashed ? "stroke-dasharray='#{dash} #{dash}' " : ""
      markers = +""
      markers << "marker-start='url(#arrowStart)' " if start_arrow
      markers << "marker-end='url(#arrow)' " if end_arrow

      # A round cap is half the stroke's width of ink past the point the stroke
      # ends at, and an arrowhead has its tip at exactly that point — so the
      # line came through the tip: 13% ink on the pixel beyond the head of a
      # path, and 81% beyond its tail, where the marker's apex sits on the
      # anchor rather than behind it. Squared off, the stroke stops where the
      # head begins. Only where there is a head: a path without one is the
      # dashed form, and every dash of it wants its round ends.
      linecap = start_arrow || end_arrow ? "butt" : "round"

      "<path d='#{rounded_polyline_d(points, radius)}' style='fill: none; stroke: #{col}; " \
        "stroke-width:#{@global[:stroke_normal]}; stroke-linecap:#{linecap}; stroke-linejoin:round;' " \
        "#{dasharray}#{markers}/>"
    end

    def draw_a_path(s_x, s_y, t_x, t_y, target_arrow = :none)
      spacing = @global[:h_gap_between_nodes] * 1.25
      min_bulge = @global[:height_connector_to_text]
      # Small enough that the turn reads as an eased corner rather than as an
      # arc, and taken from a layout measure so it holds at every font size.
      corner_radius = min_bulge / 2.0

      # Centered offset for multiple lines at the same endpoint
      s_key = "#{s_x.round}"
      t_key = "#{t_x.round}"
      @visited_x[s_key] = (@visited_x[s_key] || 0) + 1
      @visited_x[t_key] = (@visited_x[t_key] || 0) + 1
      s_offset = ((@visited_x[s_key] - 1) - (@visited_x[s_key] - 1) / 2.0) * spacing
      t_offset = ((@visited_x[t_key] - 1) - (@visited_x[t_key] - 1) / 2.0) * spacing

      dashed = true if target_arrow == :none

      if @direction == "ltr"
        # LTR: route to the RIGHT of the tree (⊃ shape / reversed C)
        # Source → right → vertical → left → Target
        xmax = [s_x, t_x].max
        bulge = [min_bulge, (s_y - t_y).abs * 0.3 + min_bulge].min
        # Ensure paths don't overlap: extend beyond previous paths
        new_x = if xmax < @width
                  @width + bulge
                else
                  xmax + bulge
                end

        new_s_y = s_y + s_offset
        new_t_y = t_y + t_offset

        @extra_lines << generate_path([[s_x, new_s_y], [new_x, new_s_y],
                                       [new_x, new_t_y], [t_x, new_t_y]],
                                      @col_path, dashed: dashed, radius: corner_radius,
                                      start_arrow: target_arrow == :double,
                                      end_arrow: target_arrow != :none)
        @width = new_x if new_x > @width
      else
        # TTB: route BELOW the tree (U shape)
        # Source → down → horizontal → up → Target
        ymax = [s_y, t_y].max
        # Proportional bulge: based on distance between endpoints,
        # not the full tree height
        bulge = [min_bulge, (s_x - t_x).abs * 0.3 + min_bulge].min
        new_y = ymax + bulge

        new_s_x = s_x - s_offset
        new_t_x = t_x - t_offset

        @extra_lines << generate_path([[new_s_x, s_y], [new_s_x, new_y],
                                       [new_t_x, new_y], [new_t_x, t_y]],
                                      @col_path, dashed: dashed, radius: corner_radius,
                                      start_arrow: target_arrow == :double,
                                      end_arrow: target_arrow != :none)
        @height = new_y if new_y > @height
      end
    end

    def draw_element(element)
      top = element.vertical_indent
      left = element.horizontal_indent
      right = left + element.content_width
      txt_pos = left + (right - left) / 2

      # Use element's custom color if specified, otherwise use default based on type
      col = if element.color
              element.color
            elsif element.type == ETYPE_LEAF
              @col_leaf
            else
              @col_node
            end

      text_data = @text_styles.sub(/COLOR/, col)
      text_data = text_data.sub(/fontsize/, @fontsize.to_s + "px;")
      # The node is laid out at the width of its label plus the room its own
      # enclosure needs, so the text starts that far inside the node's left
      # edge and the enclosure is drawn on the edge itself.
      enclosure_room = element.label_enclosure_room
      text_x = txt_pos - element.content_width / 2 + enclosure_room
      text_y = top + @global[:single_line_height] - @global[:height_connector_to_text]
      text_data  = text_data.sub(/X_VALUE/, text_x.to_s)
      text_data  = text_data.sub(/Y_VALUE/, text_y.to_s)
      new_text = +""
      this_x = 0
      this_y = 0
      prev_line_height = nil
      bc = { x: text_x - enclosure_room, y: top, width: element.content_width, height: nil }
      element.content.each_with_index do |l, idx|
        case l[:type]
        when :border, :bborder
          x1 = text_x
          if idx.zero?
            text_y -= l[:height]
          else
            text_y += l[:height]
          end
          y1 = text_y - @global[:single_line_height] / 8
          x2 = text_x + element.text_width
          y2 = y1
          case l[:type]
          when :border
            stroke_width = @global[:stroke_normal]
          when :bborder
            stroke_width = @global[:stroke_bold]
          end
          @extra_lines << "<line style=\"stroke:#{col}; fill:none; stroke-linecap:round; stroke-width:#{stroke_width}; \" x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\"></line>"
        else
          if @direction == "ltr" && element.type == ETYPE_LEAF
            # LTR leaves: left-align text at the node's left edge. A leaf
            # with its own enclosure starts one enclosure room inside, the
            # same as in TTB, or the bracket would sit on the glyphs.
            this_x = left + enclosure_room
          elsif element.enclosure == :brackets
            this_x = text_x
          else
            ewidth = 0
            l[:elements].each do |e|
              ewidth += e[:width]
            end
            this_x = txt_pos - (ewidth / 2)
          end
          # Advance by the height of the line just drawn, not of this one: a
          # row holding a nested matrix is as tall as the matrix, and the row
          # after it has to clear all of it.
          text_y += prev_line_height if idx != 0 && prev_line_height
          text_y += l[:top_room].to_f
          prev_line_height = l[:elements].map { |e| e[:height] }.max

          l[:elements].each do |e|
            if e[:decoration].include?(:matrix)
              markup, this_x = render_matrix(e, this_x, text_y, element, col)
              new_text << markup
              next
            end

            markup, this_x = render_run(e, this_x, text_y, element, col)
            new_text << markup
          end
        end
        @height = text_y if text_y > @height
      end

      bc[:y] = bc[:y] + @global[:height_connector_to_text] * 3 / 4
      # text_y is the baseline of the last line. A line holding a nested matrix
      # reaches further down than a line of text, so the label has to be given
      # the rest of it.
      overhang = prev_line_height.to_f - @global[:single_x_metrics].height
      bc[:height] = text_y - bc[:y] + @global[:height_connector_to_text] + [overhang, 0].max
      case element.enclosure
      when :brackets
        draw_bracket(bc[:x], bc[:y], bc[:width], bc[:height], col)
      when :rectangle
        draw_rectangle(bc[:x], bc[:y], bc[:width], bc[:height], col)
      when :brectangle
        draw_rectangle(bc[:x], bc[:y], bc[:width], bc[:height], col, true)
      end

      element.content_height = bc[:height]
      @tree_data += text_data.sub(/CONTENT/, new_text)
    end

    # Draws one run of a label — a stretch of text with its decorations, or the
    # box, circle or bar drawn around it — at the given pen position, and
    # reports where the pen ends up. A nested matrix draws its own runs through
    # here, so this could no longer live inside the drawing loop.
    def render_run(e, this_x, text_y, element, col)
      out = +""
      this_y = text_y
        escaped_text = e[:text].gsub('>', '&gt;').gsub('<', '&lt;');
        decorations = []
        decorations << "overline" if e[:decoration].include?(:overline)
        decorations << "underline" if e[:decoration].include?(:underline)
        decorations << "line-through" if e[:decoration].include?(:linethrough)
        decoration = "text-decoration=\"" + decorations.join(" ") + "\""

        style = "style=\""
        if e[:decoration].include?(:small)
          style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
          this_y = text_y - ((@global[:single_x_metrics].height - @global[:single_x_metrics].height * SUBSCRIPT_CONST) / 4) + @fontsize / 16.0
        elsif e[:decoration].include?(:superscript)
          style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
          this_y = text_y - (@global[:single_x_metrics].height / 4) + @fontsize / 32.0
        elsif e[:decoration].include?(:subscript)
          style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
          this_y = text_y + @fontsize / 8.0
        else
          this_y = text_y
        end

        style += "font-weight: bold; fill: #{@col_emph}; " if e[:decoration].include?(:bold) || e[:decoration].include?(:bolditalic)
        style += "font-style: italic; " if e[:decoration].include?(:italic) || e[:decoration].include?(:bolditalic)
        style += "\""

        fontstyle = FontFamily.for_svg(@fontstyle)

        if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
          # Measured around the enclosed marks in Element#setup; the line
          # height would draw the shape taller than what it encloses.
          enc_height = e[:enc_height] || e[:height]
          enc_y = this_y - (e[:enc_above] || e[:height] * 0.8)
          enc_width = e[:width]
          enc_x = this_x

          if e[:decoration].include?(:hatched)
            case element.type
            when ETYPE_LEAF
              fill = if @color
                       "url(#hatchForLeaf)"
                     else
                       "url(#hatchBlack)"
                     end
            when ETYPE_NODE
              fill = if @color
                       "url(#hatchForNode)"
                     else
                       "url(#hatchBlack)"
                     end
            end
          else
            fill = "none"
          end

          enc = nil

          stroke_width = if e[:decoration].include?(:bstroke)
                           @global[:stroke_bold]
                         else
                           @global[:stroke_normal]
                         end

          if e[:decoration].include?(:box)
            enc = "<rect style='stroke: #{col}; stroke-linejoin:round; stroke-width:#{stroke_width};'
                    x='#{enc_x}' y='#{enc_y}'
                    width='#{enc_width}' height='#{enc_height}'
                    fill='#{fill}' />\n"
          elsif e[:decoration].include?(:circle)
            enc = "<rect style='stroke: #{col}; stroke-width:#{stroke_width};'
                    x='#{enc_x}' y='#{enc_y}' rx='#{enc_height / 2}' ry='#{enc_height / 2}'
                    width='#{enc_width}' height='#{enc_height}'
                    fill='#{fill}' />\n"
          elsif e[:decoration].include?(:bar)
            x1 = enc_x
            y1 = enc_y + enc_height / 2
            x2 = enc_x + enc_width
            y2 = y1
            ar_hwidth = e[:width] / 4.0
            bar = "<line style='fill:none; stroke:#{col}; stroke-linejoin:round; stroke-linecap:round; stroke-width:#{stroke_width};' x1='#{x1 + stroke_width / 2}' y1='#{y1}' x2='#{x2 - stroke_width / 2}' y2='#{y2}'></line>\n"
            @extra_lines << bar

            if e[:decoration].include?(:arrow_to_l)
              l_arrowhead = "<polyline stroke-linejoin='round' stroke-linecap='round' fill='none' stroke='#{col}' stroke-width='#{stroke_width}' points='#{x1 + ar_hwidth},#{y1 + ar_hwidth / 2} #{x1 + stroke_width / 2},#{y1} #{x1 + ar_hwidth},#{y1 - ar_hwidth / 2}' />\n"
              @extra_lines << l_arrowhead
            end

            if e[:decoration].include?(:arrow_to_r)
              r_arrowhead = "<polyline stroke-linejoin='round' stroke-linecap='round' fill='none' stroke='#{col}' stroke-width='#{stroke_width}' points='#{x2 - ar_hwidth},#{y2 - ar_hwidth / 2} #{x2 - stroke_width / 2},#{y2} #{x2 - ar_hwidth},#{y2 + ar_hwidth / 2}' />\n"
              @extra_lines << r_arrowhead
            end
          end

          @extra_lines << enc if enc

          # Centre the marks in the shape. e[:width] is the shape's width,
          # e[:content_width] the marks' own, so half the difference is the
          # left inset — the line height used to stand in for the shape's
          # width here, which left the glyph off-centre once the shape was
          # measured from its content instead.
          inset = (e[:width] - e[:content_width]) / 2
          this_x += inset
          out << set_tspan(this_x, this_y, style, decoration, fontstyle, escaped_text)
          this_x += e[:content_width] + inset

        elsif e[:decoration].include?(:whitespace)
          return [out, this_x + e[:width]]
        else
          out << set_tspan(this_x, this_y, style, decoration, fontstyle, escaped_text)
          this_x += e[:width]
        end

      [out, this_x]
    end

    # Draws a matrix nested in a label: its own rows and columns, laid out from
    # the sizes Element#measure_lines worked out, inside its own brackets.
    def render_matrix(e, this_x, text_y, element, col)
      out = +""
      inner_x = this_x + @global[:width_half_x] * MATRIX_BRACKET_ROOM
      baseline = text_y
      prev_height = nil

      e[:matrix].each_with_index do |line, idx|
        next unless line[:type] == :text

        baseline += prev_height if idx.positive? && prev_height
        baseline += line[:top_room].to_f
        prev_height = line[:elements].map { |x| x[:height] }.max
        pen = inner_x
        line[:elements].each do |cell|
          markup, pen = if cell[:decoration].include?(:matrix)
                          render_matrix(cell, pen, baseline, element, col)
                        else
                          render_run(cell, pen, baseline, element, col)
                        end
          out << markup
        end
      end

      # The bracket encloses the matrix and its own padding. The separation
      # from the rows either side is already in the baseline this was called
      # with, so taking it off here again would cancel it out and leave two
      # stacked blocks touching.
      padding = @global[:single_x_metrics].height * MATRIX_VERTICAL_ROOM
      top = text_y - @global[:single_x_metrics].height * 0.8 - padding
      draw_bracket(this_x, top, e[:width], e[:matrix_height] + padding * 2, col)
      [out, this_x + e[:width]]
    end

    def draw_rectangle(x1, y1, width, height, col, bline = false)
      swidth = bline ? @global[:stroke_bold] : @global[:stroke_normal]
      @extra_lines << "<polygon style='stroke:#{col}; stroke-width:#{swidth}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='#{x1},#{y1} #{x1 + width},#{y1} #{x1 + width},#{y1 + height} #{x1},#{y1 + height}' />\n"
    end

    def draw_bracket(x1, y1, width, height, col, bline = false)
      swidth = bline ? @global[:stroke_bold] : @global[:stroke_normal]
      slwidth = @global[:h_gap_between_nodes] / 2
      @extra_lines << "<polyline style='stroke:#{col}; stroke-width:#{swidth}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='#{x1 + slwidth},#{y1} #{x1},#{y1} #{x1},#{y1 + height} #{x1 + slwidth},#{y1 + height}' />\n"
      @extra_lines << "<polyline style='stroke:#{col}; stroke-width:#{swidth}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='#{x1 + width - slwidth},#{y1} #{x1 + width},#{y1} #{x1 + width},#{y1 + height} #{x1 + width - slwidth},#{y1 + height}' />\n"
    end

    def set_tspan(this_x, this_y, style, decoration, fontstyle, text)
      text.gsub!(/￭+/) do |x|
        num_spaces = x.size
        "<tspan style='fill:none;'>" + "￭" * num_spaces + "</tspan>"
      end
      "<tspan x='#{this_x}' y='#{this_y}' #{style} #{decoration} font-family=\"#{fontstyle}\">#{text}</tspan>\n"
    end

    def draw_paths
      paths = []
      path_pool_target = {}
      path_pool_other = {}
      path_pool_source = {}
      path_flags = []

      line_pool = {}
      line_flags = []

      elist = @element_list.get_elements

      elist.each do |element|
        if @direction == "ltr"
          # LTR anchors: paths attach at left/right edges, vertically centered
          hctt = @global[:height_connector_to_text]
          y_center = element.vertical_indent + (element.content_height + hctt * 1.5) / 2
          x0 = element.horizontal_indent - hctt
          x1 = element.horizontal_indent + element.content_width + hctt
          x2 = element.horizontal_indent + element.content_width + hctt * 2
          y0 = y_center
          y1 = y_center
          # A line-type connection, though, wants the box's own geometry.
          # The path anchors sit a clearance off the box — right for a curve
          # leaving a node, but a straight link anchored there floats off
          # both boxes, or lands inside them when the gap is narrow.
          lgeom = {
            left: element.horizontal_indent,
            right: element.horizontal_indent + element.content_width,
            top: y_center - element.content_height / 2,
            bottom: y_center + element.content_height / 2,
            cx: element.horizontal_indent + element.content_width / 2,
            cy: y_center
          }
        else
          # x0/x2 are the box's own edges: a link between two nodes runs
          # between these plus a small margin. Anchoring a full h_gap
          # outside the box left links too short in wide gaps and pushed
          # them into the boxes in narrow ones. Only the line pool uses
          # x0/x2; movement paths read x1, which is unchanged.
          x0 = element.horizontal_indent
          x1 = element.horizontal_indent + element.content_width / 2
          x2 = element.horizontal_indent + element.content_width
          y0 = element.vertical_indent + @global[:height_connector_to_text] / 2
          y1 = element.vertical_indent + element.content_height + @global[:height_connector_to_text]
          lgeom = nil
        end
        et = element.path
        et.each do |tr|
          if /\A-(>|<)?(\d+)\z/ =~ tr
            arrow = $1
            tr = $2
            if line_pool[tr]
              line_pool[tr] << { x: { left: x0, center: x1, right: x2 }, y: { top: y0, center: y0 + (y1 - y0) / 2, bottom: y1 }, arrow: arrow, geom: lgeom }
            else
              line_pool[tr] = [{ x: { left: x0, center: x1, right: x2 }, y: { top: y0, center: y0 + (y1 - y0) / 2, bottom: y1 }, arrow: arrow, geom: lgeom }]
            end
            line_flags << tr
          elsif /\A(?:>|<)(\d+)\z/ =~ tr
            tr = $1
            if path_pool_target[tr]
              path_pool_target[tr] << [x1, y1]
            else
              path_pool_target[tr] = [[x1, y1]]
            end
            path_flags << tr
          elsif path_pool_source[tr]
            if path_pool_other[tr]
              path_pool_other[tr] << [x1, y1]
            else
              path_pool_other[tr] = [[x1, y1]]
            end
            path_flags << tr
          else
            path_pool_source[tr] = [x1, y1]
            path_flags << tr
          end
          raise RSTError.new(+"Error: input text contains a path having more than two ends:\n > #{tr}", code: :path_multiple_ends, hint: "A path or line takes exactly two ends; check the numbers.", retryable: true) if path_flags.tally.any? { |_k, v| v > 2 } || line_flags.tally.any? { |_k, v| v > 2 }
        end
      end

      path_flags.tally.each do |k, v|
        raise RSTError.new(+"Error: input text contains a path having only one end:\n > #{k}", code: :path_single_end, hint: "A path takes two ends: one '+N' on each of two nodes.", retryable: true) if v == 1
      end

      # A line-type connection is subject to the same rule as a path: it takes
      # two ends. Without this the drawing walked off a nil pool below.
      line_flags.tally.each do |k, v|
        raise RSTError.new(+"Error: input text contains a line having only one end:\n > #{k}", code: :path_single_end, hint: "A line connection takes two ends: '+-N' on each of two nodes.", retryable: true) if v == 1
      end

      path_pool_source.each do |k, v|
        path_flags.delete(k)
        if (targets = path_pool_target[k])
          targets.each do |t|
            paths << { x1: v[0], y1: v[1], x2: t[0], y2: t[1], arrow: :single }
          end
        elsif (others = path_pool_other[k])
          others.each do |t|
            paths << { x1: v[0], y1: v[1], x2: t[0], y2: t[1], arrow: :none }
          end
        end
      end

      path_flags.uniq.each do |k|
        targets = path_pool_target[k]
        next if targets.nil? || targets.empty?

        fst = targets.shift
        next if fst.nil?

        targets.each do |t|
          paths << { x1: fst[0], y1: fst[1], x2: t[0], y2: t[1], arrow: :double }
        end
      end

      paths.each do |t|
        draw_a_path(t[:x1], t[:y1], t[:x2], t[:y2], t[:arrow])
      end

      line_pool.each do |_k, v|
        a = v[0]
        b = v[1]

        # A straight link stops a small margin short of each box. The margin
        # scales with the inter-node gap and is clamped so an endpoint can
        # never cross the facing edge.
        margin = @global[:h_gap_between_nodes] * 0.25
        inset = ->(gap) { [[margin, gap / 2 - 1].min, 0].max }

        if @direction == "ltr"
          # LTR: use x-position to determine depth relationship,
          # y-position for sibling relationship
          ga = a[:geom]
          gb = b[:geom]
          if ga[:left] > gb[:right]
            m = inset.call(ga[:left] - gb[:right])
            generate_connectors(ga[:left] - m, ga[:cy], gb[:right] + m, gb[:cy], @col_extra, false, a[:arrow], b[:arrow])
          elsif ga[:right] < gb[:left]
            m = inset.call(gb[:left] - ga[:right])
            generate_connectors(gb[:left] - m, gb[:cy], ga[:right] + m, ga[:cy], @col_extra, false, b[:arrow], a[:arrow])
          elsif ga[:cy] < gb[:cy]
            m = inset.call(gb[:top] - ga[:bottom])
            generate_connectors(ga[:cx], ga[:bottom] + m, ga[:cx], gb[:top] - m, @col_extra, false, a[:arrow], b[:arrow])
          else
            m = inset.call(ga[:top] - gb[:bottom])
            generate_connectors(gb[:cx], gb[:bottom] + m, gb[:cx], ga[:top] - m, @col_extra, false, b[:arrow], a[:arrow])
          end
        else
          # TTB: use y-position to determine depth relationship
          if a[:y][:top] > b[:y][:bottom]
            generate_connectors(a[:x][:center], a[:y][:top], b[:x][:center], b[:y][:bottom], @col_extra, false, a[:arrow], b[:arrow])
          elsif a[:y][:bottom] < b[:y][:top]
            generate_connectors(b[:x][:center], b[:y][:top], a[:x][:center], a[:y][:bottom], @col_extra, false, b[:arrow], a[:arrow])
          elsif a[:x][:center] < b[:x][:center]
            m = inset.call(b[:x][:left] - a[:x][:right])
            if a[:y][:top] == b[:y][:top]
              upper_y = a[:y][:center] < b[:y][:center] ? a[:y][:center] : b[:y][:center]
              generate_connectors(a[:x][:right] + m, upper_y, b[:x][:left] - m, upper_y, @col_extra, false, a[:arrow], b[:arrow])
            else
              generate_connectors(a[:x][:right] + m, a[:y][:center], b[:x][:left] - m, b[:y][:center], @col_extra, false, a[:arrow], b[:arrow])
            end
          elsif a[:y][:top] == b[:y][:top]
            upper_y = a[:y][:center] < b[:y][:center] ? a[:y][:center] : b[:y][:center]
            m = inset.call(a[:x][:left] - b[:x][:right])
            generate_connectors(b[:x][:right] + m, upper_y, a[:x][:left] - m, upper_y, @col_extra, false, b[:arrow], a[:arrow])
          else
            m = inset.call(a[:x][:left] - b[:x][:right])
            generate_connectors(b[:x][:right] + m, b[:y][:center], a[:x][:left] - m, a[:y][:center], @col_extra, false, b[:arrow], a[:arrow])
          end
        end
      end
      paths.size + line_pool.keys.size
    end

    def generate_connectors(x1, y1, x2, y2, col, dashed = false, s_arrow = false, t_arrow = false, bline = false)
      string = if s_arrow && t_arrow
                 "" # bothways arrowheads are drawn as chevrons below
               elsif s_arrow
                 "marker-mid='url(#arrowForward)' "
               elsif t_arrow
                 "marker-mid='url(#arrowBackward)' "
               else
                 ""
               end
      dash = @fontsize / 4.0
      dasharray = dashed ? "stroke-dasharray='#{dash} #{dash}'" : ""
      swidth = bline ? @global[:stroke_bold] : @global[:stroke_normal]

      if s_arrow && t_arrow
        @extra_lines << "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}; stroke-linecap:round;' #{dasharray}/>"
        @extra_lines << bothways_arrows(x1, y1, x2, y2, col, swidth)
      elsif s_arrow || t_arrow
        x_mid = if x2 > x1
                  x1 + (x2 - x1) / 2
                else
                  x1 - (x1 - x2) / 2
                end
        y_mid = if y2 > y1
                  y1 + (y2 - y1) / 2
                else
                  y1 - (y1 - y2) / 2
                end
        @extra_lines << "<path d='M#{x1},#{y1} L#{x_mid},#{y_mid} L#{x2}, #{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}; stroke-linecap:round;' #{dasharray} #{string}/>"
      else
        @extra_lines << "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}; stroke-linecap:round;' #{dasharray} #{string}/>"
      end
    end

    # Two arrowheads back to back at the midpoint of a link, drawn as filled
    # triangles sized to the link itself. The arrowBothways marker this
    # replaces was one fixed size — three inter-node gaps wide — so on a
    # short link between narrow-spaced boxes it spilled over both of them.
    def bothways_arrows(x1, y1, x2, y2, col, swidth)
      len = Math.hypot(x2 - x1, y2 - y1)
      return "" if len.zero?

      ux = (x2 - x1) / len
      uy = (y2 - y1) / len
      mx = (x1 + x2) / 2
      my = (y1 + y2) / 2

      # Same proportions the marker had — three inter-node gaps end to end,
      # one deep, two heads with a shaft's worth of daylight between them —
      # so a link long enough to hold it looks as it always did. What is new
      # is that a shorter link gets the same shape at a smaller size instead
      # of the one fixed size spilling over the boxes on either side.
      span = [@global[:h_gap_between_nodes] * 3, len * 0.8].min
      head = span / 3.0
      half = head / 2.0

      arrow = lambda do |dir|
        tip_x = mx + ux * (span / 2.0) * dir
        tip_y = my + uy * (span / 2.0) * dir
        base_x = mx + ux * half * dir
        base_y = my + uy * half * dir
        "<polygon points='#{tip_x},#{tip_y} " \
          "#{base_x - uy * half},#{base_y + ux * half} " \
          "#{base_x + uy * half},#{base_y - ux * half}' " \
          "style='fill:#{col}; stroke:none;' />"
      end

      arrow.call(1) + "\n" + arrow.call(-1)
    end

    def generate_line(x1, y1, x2, y2, col, dashed = false, arrow = false, bline = false)
      string = if arrow
                 "marker-end='url(#arrow)' "
               else
                 ""
               end
      dash = @fontsize / 4.0
      dasharray = dashed ? "stroke-dasharray='#{dash} #{dash}'" : ""
      swidth = bline ? @global[:stroke_bold] : @global[:stroke_normal]

      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}; stroke-linecap:round;' #{dasharray} #{string}/>"
    end

    # Draw a line between child/parent elements. An empty-label element
    # (see Element#empty_label?) is a pass-through joint: the line runs to
    # its center instead of stopping at its (invisible) text box, so the
    # segments on both sides connect without a gap.
    # One rule across all the premises, in place of a line to each. The rule
    # runs the width of what it combines — the span from the leftmost child's
    # left edge to the rightmost child's right edge — because that span is what
    # the step applies to, and reading it off the children is what keeps it
    # right when the layout moves.
    #
    # Drawn at the parent's edge facing the children, so it sits between the
    # material above it and the result below in a derivation, and between a
    # node and its daughters in an ordinary tree.
    def rule_to_parent(parent, children)
      return if children.empty?

      # The whole of what the step combines, not the labels of its premises:
      # a premise stands over a derivation of its own, and the rule is drawn
      # across all of it. Taken from the subtree extents, which is what the
      # layout already computes for the same purpose.
      left = children.map { |c| get_leftmost(c.id) }.min
      right = children.map { |c| get_rightmost(c.id) }.max
      # The parent may be wider than everything it combines, which happens when
      # a category is longer than the words under it. The rule covers both, so
      # that the label it belongs to is never wider than its own rule.
      left = [left, parent.horizontal_indent].min
      right = [right, parent.horizontal_indent + parent.content_width].max

      hctt = @global[:height_connector_to_text]
      above, below = derivation_rule_band(parent)
      y = if above
            (above + hctt + below) / 2.0
          else
            child_edge = children.map { |c| c.vertical_indent + c.content_height }.max
            parent_top = parent.vertical_indent
            if parent_top >= child_edge
              # The parent sits below: the rule goes between the two.
              (child_edge + hctt + parent_top) / 2.0
            else
              # The parent sits above (an ordinary top-to-bottom tree).
              (parent.vertical_indent + parent.content_height + hctt +
               children.map(&:vertical_indent).min) / 2.0
            end
          end

      @tree_data += @line_styles.sub(/X1/, left.to_s).sub(/Y1/, y.to_s)
                                .sub(/X2/, right.to_s).sub(/Y2/, y.to_s)

      draw_rule_name(parent, right, y)
    end

    # The name of the rule, set beside the end of its own line and smaller than
    # the categories, which is where a derivation puts it and how it keeps the
    # name from reading as part of either row.
    def draw_rule_name(parent, right, y)
      name = parent.rule_name
      return if name.nil? || name.empty?

      size = (@fontsize * 0.8).round(2)
      # Level with the rule, by the same reckoning an enclosure uses to sit
      # level with what it encloses.
      baseline = y + FontMetrics.visual_centre(@fontset[:family], size)
      x = right + @global[:width_half_x]
      # The name is the one thing drawn outside every element's own box, so the
      # canvas has to be told where it ends or the last step's name is cut off
      # at the edge of the image.
      edge = x + FontMetrics.get_metrics(name, @fontset[:family], size, :normal, :normal).width
      @rule_name_edge = edge if edge > @rule_name_edge.to_f
      @tree_data += @text_styles.sub(/COLOR/, @col_line)
                                .sub(/fontsize/, size.to_s + "px;")
                                .sub(/X_VALUE/, x.to_s)
                                .sub(/Y_VALUE/, baseline.round(2).to_s)
                                .sub(/CONTENT/) { CGI.escapeHTML(name) }
    end

    # Where a connector meets each box in a vertical layout: the underside of
    # whichever sits higher and the top of whichever sits lower. Turned over,
    # the parent is the lower of the two, and keeping the top-to-bottom edges
    # sent the line back up through both labels. An empty label has no text to
    # clear, so the line runs to its middle.
    def connector_edges(child, parent)
      hctt = @global[:height_connector_to_text]
      child_above = child.vertical_indent <= parent.vertical_indent

      child_y = if child.empty_label?
                  child.vertical_indent + child.content_height / 2
                elsif child_above
                  child.vertical_indent + child.content_height + hctt
                else
                  child.vertical_indent + hctt / 2
                end

      parent_y = if parent.empty_label?
                   parent.vertical_indent + parent.content_height / 2
                 elsif child_above
                   parent.vertical_indent + hctt / 2
                 else
                   parent.vertical_indent + parent.content_height + hctt
                 end

      [child_y, parent_y]
    end

    def line_to_parent(parent, child)
      return if child.horizontal_indent.zero?

      if @direction == "ltr"
        # LTR: parent's right side → child's left side
        # Y center = midpoint between TTB top-connection and bottom-connection
        # top = vi + hctt/2, bottom = vi + content_height + hctt
        # midpoint = vi + (content_height + hctt * 1.5) / 2
        hctt = @global[:height_connector_to_text]
        y1 = child.vertical_indent + (child.content_height + hctt * 1.5) / 2
        y2 = parent.vertical_indent + (parent.content_height + hctt * 1.5) / 2
        x1 = child.empty_label? ? child.horizontal_indent + child.content_width / 2 : child.horizontal_indent - hctt
        x2 = parent.empty_label? ? parent.horizontal_indent + parent.content_width / 2 : parent.horizontal_indent + parent.content_width + hctt

        if @polyline
          mid_x1 = x2 + (x1 - x2) / 2
          mid_y1 = y1
          mid_x2 = mid_x1
          mid_y2 = y2
          @tree_data += @polyline_styles.sub(/CHIX/, x1.to_s)
                                        .sub(/CHIY/, y1.to_s)
                                        .sub(/MIDX1/, mid_x1.to_s)
                                        .sub(/MIDY1/, mid_y1.to_s)
                                        .sub(/MIDX2/, mid_x2.to_s)
                                        .sub(/MIDY2/, mid_y2.to_s)
                                        .sub(/PARX/, x2.to_s)
                                        .sub(/PARY/, y2.to_s)
        else
          line_data   = @line_styles.sub(/X1/, x1.to_s)
          line_data   = line_data.sub(/Y1/, y1.to_s)
          line_data   = line_data.sub(/X2/, x2.to_s)
          @tree_data += line_data.sub(/Y2/, y2.to_s)
        end
      else
        # TTB: parent's bottom → child's top
        if @polyline
          chi_x = child.horizontal_indent + child.content_width / 2
          par_x = parent.horizontal_indent + parent.content_width / 2
          chi_y, par_y = connector_edges(child, parent)

          mid_x1 = chi_x
          mid_y1 = par_y + (chi_y - par_y) / 2

          mid_x2 = par_x
          mid_y2 = mid_y1

          @tree_data += @polyline_styles.sub(/CHIX/, chi_x.to_s)
                                        .sub(/CHIY/, chi_y.to_s)
                                        .sub(/MIDX1/, mid_x1.to_s)
                                        .sub(/MIDY1/, mid_y1.to_s)
                                        .sub(/MIDX2/, mid_x2.to_s)
                                        .sub(/MIDY2/, mid_y2.to_s)
                                        .sub(/PARX/, par_x.to_s)
                                        .sub(/PARY/, par_y.to_s)
        else
          x1 = child.horizontal_indent + child.content_width / 2
          x2 = parent.horizontal_indent + parent.content_width / 2
          y1, y2 = connector_edges(child, parent)

          line_data   = @line_styles.sub(/X1/, x1.to_s)
          line_data   = line_data.sub(/Y1/, y1.to_s)
          line_data   = line_data.sub(/X2/, x2.to_s)
          @tree_data += line_data.sub(/Y2/, y2.to_s)
        end
      end
    end

    # Draw a triangle between child/parent elements
    def triangle_to_parent(parent, child)
      return if child.horizontal_indent.zero?

      if @direction == "ltr"
        # LTR: triangle opens vertically (top-bottom of child),
        # apex at parent's right side.
        # Use same vertical reference and dimensions as TTB uses horizontally.
        hctt = @global[:height_connector_to_text]
        child_y_center = child.vertical_indent + (child.content_height + hctt * 1.5) / 2
        parent_y_center = parent.vertical_indent + (parent.content_height + hctt * 1.5) / 2
        tri_half = @global[:single_x_metrics].height / 2
        x1 = child.horizontal_indent - @global[:height_connector_to_text] / 2
        y1 = child_y_center - tri_half
        x2 = child.horizontal_indent - @global[:height_connector_to_text] / 2
        y2 = child_y_center + tri_half
        x3 = parent.horizontal_indent + parent.content_width + @global[:height_connector_to_text]
        y3 = parent_y_center
      else
        # TTB: triangle opens horizontally (left-right of child text),
        # apex at parent's bottom
        x1 = child.horizontal_indent
        y1 = child.vertical_indent + @global[:height_connector_to_text] / 2
        x2 = child.horizontal_indent + child.content_width
        y2 = child.vertical_indent + @global[:height_connector_to_text] / 2
        x3 = parent.horizontal_indent + parent.content_width / 2
        y3 = parent.vertical_indent + parent.content_height + @global[:height_connector_to_text]
      end

      polygon_data = @polygon_styles.sub(/X1/, x1.to_s)
      polygon_data = polygon_data.sub(/Y1/, y1.to_s)
      polygon_data = polygon_data.sub(/X2/, x2.to_s)
      polygon_data = polygon_data.sub(/Y2/, y2.to_s)
      polygon_data = polygon_data.sub(/X3/, x3.to_s)
      @tree_data  += polygon_data.sub(/Y3/, y3.to_s)
    end
  end
end
