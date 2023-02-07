# frozen_string_literal: true

#==========================
# svg_graph.rb
#==========================
#
# Parses an element list into an SVG tree.
# Copyright (c) 2007-2023 Yoichiro Hasebe <yohasebe@gmail.com>

require "tempfile"
require_relative 'base_graph'
require_relative 'utils'

module RSyntaxTree
  class SVGGraph < BaseGraph
    attr_accessor :width, :height

    def initialize(element_list, params, global)
      super(element_list, params, global)
      @height = 0
      @width  = 0
      @extra_lines = []
      @fontset = params[:fontset]
      @fontsize = params[:fontsize]
      @linewidth = params[:linewidth]
      @transparent = params[:transparent]
      @color = params[:color]
      @fontstyle = params[:fontstyle]
      @polyline = params[:polyline]
      @line_styles = "<line style='stroke:#{@col_line}; stroke-width:#{@linewidth + LINE_SCALING}; stroke-linejoin:round; stroke-linecap:round;' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
      @polyline_styles = "<polyline style='stroke:#{@col_line}; stroke-width:#{@linewidth + LINE_SCALING}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='CHIX CHIY MIDX1 MIDY1 MIDX2 MIDY2 PARX PARY' />\n"
      @polygon_styles = "<polygon style='fill: none; stroke: black; stroke-width:#{@linewidth + LINE_SCALING}; stroke-linejoin:round;stroke-linecap:round;' points='X1 Y1 X2 Y2 X3 Y3' />\n"
      @text_styles = "<text white-space='pre' alignment-baseline='text-top' style='fill: COLOR; font-size: fontsize' x='X_VALUE' y='Y_VALUE'>CONTENT</text>\n"
      @tree_data = String.new
      @visited_x = {}
      @visited_y = {}
      @global = global
    end

    def svg_data
      metrics = parse_list

      @height = metrics[:height] + @global[:height_connector_to_text] / 2
      @width = metrics[:width] + @global[:h_gap_between_nodes] / 2

      x1 = 0
      y1 = 0
      x2 = @width + @global[:h_gap_between_nodes] / 2
      y2 = @height + @global[:height_connector_to_text] / 2

      extra_lines = @extra_lines.join("\n")

      as2 = @global[:h_gap_between_nodes] * 1.0
      as4 = as2 * 3

      header = <<~HDR
        <?xml version="1.0" standalone="no"?>
        <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
          <svg width="#{@width}" height="#{@height}" viewBox="#{x1}, #{y1}, #{x2}, #{y2}" version="1.1" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <marker id="arrow" markerUnits="userSpaceOnUse" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="#{as2}" markerHeight="#{as2}" orient="auto">
              <path d="M 0 0 L 10 5 L 0 10" fill="#{@col_extra}"/>
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
            <pattern id="hatchBlack" x="10" y="10" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="10" stroke="black" stroke-width="4"></line>
            </pattern>
            <pattern id="hatchForNode" x="10" y="10" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="10" stroke="#{@col_node}" stroke-width="4"></line>
            </pattern>
            <pattern id="hatchForLeaf" x="10" y="10" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1="0" y="0" x2="0" y2="10" stroke="#{@col_leaf}" stroke-width="4"></line>
            </pattern>
          </defs>
      HDR

      rect = <<~RCT
        <rect x="#{x1}" y="#{y1}" width="#{x2}" height="#{y2}" stroke="none" fill="white" />"
      RCT

      footer = "</svg>"

      if @transparent
        header + @tree_data + extra_lines + footer
      else
        header + rect + @tree_data + extra_lines + footer
      end
    end

    def draw_a_path(s_x, s_y, t_x, t_y, target_arrow = :none)
      x_spacing = @global[:h_gap_between_nodes] * 1.25
      y_spacing = @global[:height_connector] * 0.75

      ymax = [s_y, t_y].max
      new_y = if ymax < @height
                @height + y_spacing
              else
                ymax + y_spacing
              end

      if @visited_x[s_x]
        new_s_x = s_x - x_spacing * @visited_x[s_x]
        @visited_x[s_x] += 1
      else
        new_s_x = s_x
        @visited_x[s_x] = 1
      end

      if @visited_x[t_x]
        new_t_x = t_x - x_spacing * @visited_x[t_x]
        @visited_x[t_x] += 1
      else
        new_t_x = t_x
        @visited_x[t_x] = 1
      end

      dashed = true if target_arrow == :none

      case target_arrow
      when :single
        @extra_lines << generate_line(new_s_x, s_y, new_s_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_s_x, s_y, new_s_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path, dashed, true)
      when :double
        @extra_lines << generate_line(new_s_x, new_y, new_s_x, s_y, @col_path, dashed, true)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path, dashed, true)
      else
        @extra_lines << generate_line(new_s_x, s_y, new_s_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path, dashed)
      end
      @height = new_y if new_y > @height
    end

    def draw_element(element)
      top = element.vertical_indent
      left = element.horizontal_indent
      right = left + element.content_width
      txt_pos = left + (right - left) / 2

      col = if element.type == ETYPE_LEAF
              @col_leaf
            else
              @col_node
            end

      text_data = @text_styles.sub(/COLOR/, col)
      text_data = text_data.sub(/fontsize/, @fontsize.to_s + "px;")
      text_x = txt_pos - element.content_width / 2
      text_y = top + @global[:single_line_height] - @global[:height_connector_to_text]
      text_data  = text_data.sub(/X_VALUE/, text_x.to_s)
      text_data  = text_data.sub(/Y_VALUE/, text_y.to_s)
      new_text = +""
      this_x = 0
      this_y = 0
      bc = { x: text_x - @global[:h_gap_between_nodes] / 2, y: top, width: element.content_width + @global[:h_gap_between_nodes], height: nil }
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
          x2 = text_x + element.content_width
          y2 = y1
          case l[:type]
          when :border
            stroke_width = @linewidth + LINE_SCALING
          when :bborder
            stroke_width = @linewidth + BLINE_SCALING
          end
          @extra_lines << "<line style=\"stroke:#{col}; stroke-linecap:round; stroke-width:#{stroke_width}; \" x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\"></line>"
        else
          if element.enclosure == :brackets
            this_x = txt_pos - element.content_width / 2
          else
            ewidth = 0
            l[:elements].each do |e|
              ewidth += e[:width]
            end
            this_x = txt_pos - (ewidth / 2)
          end
          text_y += l[:elements].map { |e| e[:height] }.max if idx != 0

          l[:elements].each do |e|
            escaped_text = e[:text].gsub('>', '&gt;').gsub('<', '&lt;');
            decorations = []
            decorations << "overline" if e[:decoration].include?(:overline)
            decorations << "underline" if e[:decoration].include?(:underline)
            decorations << "line-through" if e[:decoration].include?(:linethrough)
            decoration = "text-decoration=\"" + decorations.join(" ") + "\""

            style = "style=\""
            if e[:decoration].include?(:small)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y - ((@global[:single_x_metrics].height - @global[:single_x_metrics].height * SUBSCRIPT_CONST) / 4) + 2
            elsif e[:decoration].include?(:superscript)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y - (@global[:single_x_metrics].height / 4) + 1
            elsif e[:decoration].include?(:subscript)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y + 4
            else
              this_y = text_y
            end

            style += "font-weight: bold; fill: #{@col_emph}; " if e[:decoration].include?(:bold) || e[:decoration].include?(:bolditalic)
            style += "font-style: italic; " if e[:decoration].include?(:italic) || e[:decoration].include?(:bolditalic)
            style += "\""

            case @fontstyle
            when /(?:cjk)/
              fontstyle = "'WenQuanYi Zen Hei', 'Noto Sans', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
            when /(?:mono)/
              fontstyle = if e[:cjk]
                            "'Noto Sans JP', 'Noto Sans Mono SemiCondensed', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
                          else
                            "'Noto Sans Mono SemiCondensed', 'Noto Sans JP', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
                          end
            when /(?:sans)/
              fontstyle = if e[:cjk]
                            "'Noto Sans JP', 'Noto Sans', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
                          else
                            "'Noto Sans', 'Noto Sans JP', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
                          end
            when /(?:serif)/
              fontstyle = if e[:cjk]
                            "'Noto Serif JP', 'Noto Serif', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', serif"
                          else
                            "'Noto Serif', 'Noto Serif JP', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', serif"
                          end
            end

            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              enc_height = e[:height]
              enc_y = this_y - e[:height] * 0.8 + FONT_SCALING
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
                               @linewidth + BLINE_SCALING
                             else
                               @linewidth + LINE_SCALING
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
                bar = "<line style='stroke:#{col}; stroke-linejoin:round; stroke-linecap:round; stroke-width:#{stroke_width};' x1='#{x1}' y1='#{y1}' x2='#{x2 - stroke_width / 2}' y2='#{y2}'></line>\n"
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

              this_x += if e[:text].size == 1
                          (e[:height] - e[:content_width]) / 2
                        else
                          @global[:width_half_x] / 2
                        end

              new_text << set_tspan(this_x, this_y, style, decoration, fontstyle, escaped_text)
              this_x += if e[:text].size == 1
                          e[:content_width] + (e[:height] - e[:content_width]) / 2
                        else
                          e[:content_width] + @global[:width_half_x] / 2
                        end

            elsif e[:decoration].include?(:whitespace)
              this_x += e[:width]
              next
            else
              new_text << set_tspan(this_x, this_y, style, decoration, fontstyle, escaped_text)
              this_x += e[:width]
            end
          end
        end
        @height = text_y if text_y > @height
      end

      bc[:y] = bc[:y] + @global[:height_connector_to_text] * 3 / 4
      bc[:height] = text_y - bc[:y] + @global[:height_connector_to_text]
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

    def draw_rectangle(x1, y1, width, height, col, bline = false)
      swidth = bline ? @linewidth + BLINE_SCALING : @linewidth + LINE_SCALING
      @extra_lines << "<polygon style='stroke:#{col}; stroke-width:#{swidth}; fill:none; stroke-linejoin:round; stroke-linecap:round;'
                            points='#{x1},#{y1} #{x1 + width},#{y1} #{x1 + width},#{y1 + height} #{x1},#{y1 + height}' />\n"
    end

    def draw_bracket(x1, y1, width, height, col, bline = false)
      swidth = bline ? @linewidth + BLINE_SCALING : @linewidth + LINE_SCALING
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
        x0 = element.horizontal_indent - @global[:h_gap_between_nodes]
        x1 = element.horizontal_indent + element.content_width / 2
        x2 = element.horizontal_indent + element.content_width + @global[:h_gap_between_nodes]
        y0 = element.vertical_indent + @global[:height_connector_to_text] / 2
        y1 = element.vertical_indent + element.content_height + @global[:height_connector_to_text]
        et = element.path
        et.each do |tr|
          if /\A-(>|<)?(\d+)\z/ =~ tr
            arrow = $1
            tr = $2
            if line_pool[tr]
              line_pool[tr] << { x: { left: x0, center: x1, right: x2 }, y: { top: y0, center: y0 + (y1 - y0) / 2, bottom: y1 }, arrow: arrow }
            else
              line_pool[tr] = [{ x: { left: x0, center: x1, right: x2 }, y: { top: y0, center: y0 + (y1 - y0) / 2, bottom: y1 }, arrow: arrow }]
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
          raise RSTError, +"Error: input text contains a path having more than two ends:\n > #{tr}" if path_flags.tally.any? { |_k, v| v > 2 } || line_flags.tally.any? { |_k, v| v > 2 }
        end
      end

      path_flags.tally.each do |k, v|
        raise RSTError, +"Error: input text contains a path having only one end:\n > #{k}" if v == 1
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
        fst = targets.shift
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

        if a[:y][:top] > b[:y][:bottom]
          generate_connectors(a[:x][:center], a[:y][:top], b[:x][:center], b[:y][:bottom], @col_extra, false, a[:arrow], b[:arrow])
        elsif a[:y][:bottom] < b[:y][:top]
          generate_connectors(b[:x][:center], b[:y][:top], a[:x][:center], a[:y][:bottom], @col_extra, false, b[:arrow], a[:arrow])
        elsif a[:x][:center] < b[:x][:center]
          if a[:y][:top] == b[:y][:top]
            upper_y = a[:y][:center] < b[:y][:center] ? a[:y][:center] : b[:y][:center]
            generate_connectors(a[:x][:right], upper_y, b[:x][:left], upper_y, @col_extra, false, a[:arrow], b[:arrow])
          else
            generate_connectors(a[:x][:right], a[:y][:center], b[:x][:left], b[:y][:center], @col_extra, false, a[:arrow], b[:arrow])
          end
        elsif a[:y][:top] == b[:y][:top]
          upper_y = a[:y][:center] < b[:y][:center] ? a[:y][:center] : b[:y][:center]
          generate_connectors(b[:x][:right], upper_y, a[:x][:left], upper_y, @col_extra, false, b[:arrow], a[:arrow])
        else
          generate_connectors(b[:x][:right], b[:y][:center], a[:x][:left], a[:y][:center], @col_extra, false, b[:arrow], a[:arrow])
        end
      end
      paths.size + line_pool.keys.size
    end

    def generate_connectors(x1, y1, x2, y2, col, dashed = false, s_arrow = false, t_arrow = false, bline = false)
      string = if s_arrow && t_arrow
                 "marker-mid='url(#arrowBothways)' "
               elsif s_arrow
                 "marker-mid='url(#arrowForward)' "
               elsif t_arrow
                 "marker-mid='url(#arrowBackward)' "
               else
                 ""
               end
      dasharray = dashed ? "stroke-dasharray='8 8'" : ""
      swidth = bline ? @linewidth + BLINE_SCALING : @linewidth + LINE_SCALING

      if s_arrow || t_arrow
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

    def generate_line(x1, y1, x2, y2, col, dashed = false, arrow = false, bline = false)
      string = if arrow
                 "marker-end='url(#arrow)' "
               else
                 ""
               end
      dasharray = dashed ? "stroke-dasharray='8 8'" : ""
      swidth = bline ? @linewidth + BLINE_SCALING : @linewidth + LINE_SCALING

      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}; stroke-linecap:round;' #{dasharray} #{string}/>"
    end

    # Draw a line between child/parent elements
    def line_to_parent(parent, child)
      return if child.horizontal_indent.zero?

      if @polyline
        chi_x = child.horizontal_indent + child.content_width / 2
        chi_y = child.vertical_indent + @global[:height_connector_to_text] / 2

        par_x = parent.horizontal_indent + parent.content_width / 2
        par_y = parent.vertical_indent + parent.content_height + @global[:height_connector_to_text]

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
        y1 = child.vertical_indent + @global[:height_connector_to_text] / 2
        x2 = parent.horizontal_indent + parent.content_width / 2
        y2 = parent.vertical_indent + parent.content_height + @global[:height_connector_to_text]

        line_data   = @line_styles.sub(/X1/, x1.to_s)
        line_data   = line_data.sub(/Y1/, y1.to_s)
        line_data   = line_data.sub(/X2/, x2.to_s)
        @tree_data += line_data.sub(/Y2/, y2.to_s)
      end
    end

    # Draw a triangle between child/parent elements
    def triangle_to_parent(parent, child)
      return if child.horizontal_indent.zero?

      x1 = child.horizontal_indent
      y1 = child.vertical_indent + @global[:height_connector_to_text] / 2
      x2 = child.horizontal_indent + child.content_width
      y2 = child.vertical_indent + @global[:height_connector_to_text] / 2
      x3 = parent.horizontal_indent + parent.content_width / 2
      y3 = parent.vertical_indent + parent.content_height + @global[:height_connector_to_text]

      polygon_data = @polygon_styles.sub(/X1/, x1.to_s)
      polygon_data = polygon_data.sub(/Y1/, y1.to_s)
      polygon_data = polygon_data.sub(/X2/, x2.to_s)
      polygon_data = polygon_data.sub(/Y2/, y2.to_s)
      polygon_data = polygon_data.sub(/X3/, x3.to_s)
      @tree_data  += polygon_data.sub(/Y3/, y3.to_s)
    end
  end
end
