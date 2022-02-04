#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# svg_graph.rb
#==========================
#
# Parses an element list into an SVG tree.
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>

require "tempfile"
require 'base_graph'
require 'utils'

module RSyntaxTree
  class SVGGraph < BaseGraph
    attr_accessor :width, :height

    def initialize(element_list, params)
      @height = 0
      @width  = 0
      @extra_lines = []
      @fontset  = params[:fontset]
      @fontsize  = params[:fontsize]
      @transparent = params[:transparent]
      @color = params[:color]
      @fontstyle = params[:fontstyle]
      @margin = params[:margin].to_i
      @polyline = params[:polyline]
      @line_styles  = "<line style='stroke:black; stroke-width:#{FONT_SCALING};' x1='X1' y1='Y1' x2='X2' y2='Y2' />\n"
      @polyline_styles  = "<polyline style='stroke:black; stroke-width:#{FONT_SCALING}; fill:none;' 
                            points='CHIX CHIY MIDX1 MIDY1 MIDX2 MIDY2 PARX PARY' />\n"
      @polygon_styles  = "<polygon style='fill: none; stroke: black; stroke-width:#{FONT_SCALING};' points='X1 Y1 X2 Y2 X3 Y3' />\n"
      @text_styles  = "<text white-space='pre' alignment-baseline='text-top' style='fill: COLOR; font-size: fontsize' x='X_VALUE' y='Y_VALUE'>CONTENT</text>\n"
      @tree_data  = String.new
      @visited_x = {}
      @visited_y = {}
      super(element_list, params)
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

      as2  = $h_gap_between_nodes / 2 * 0.8
      as = as2 / 2

      header =<<EOD
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
  <svg width="#{@width}" height="#{@height}" viewBox="#{x1}, #{y1}, #{x2}, #{y2}" version="1.1" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrow" markerUnits="strokeWidth" markerWidth="#{as2}" markerHeight="#{as2}" viewBox="0 0 #{as2} #{as2}" refX="#{as}" refY="0">
      <polyline fill="none" stroke="#{@col_path}" stroke-width="1" points="0,#{as2},#{as},0,#{as2},#{as2}" />
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

    def draw_a_path(s_x, s_y, t_x, t_y, target_arrow = :none)

      x_spacing = $h_gap_between_nodes * 1.25
      y_spacing = $height_connector * 0.65

      ymax = [s_y, t_y].max
      if ymax  < @height
        new_y = @height + y_spacing
      else
        new_y = ymax + y_spacing
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

      s_y += $h_gap_between_nodes / 2
      t_y += $h_gap_between_nodes / 2
      new_y += $h_gap_between_nodes / 2

      dashed = true if target_arrow == :none

      if target_arrow == :single
        @extra_lines << generate_line(new_s_x, s_y, new_s_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path ,dashed, true)
      elsif target_arrow == :double
        @extra_lines << generate_line(new_s_x, new_y, new_s_x, s_y, @col_path, dashed, true)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path ,dashed, true)
      else
        @extra_lines << generate_line(new_s_x, s_y, new_s_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_s_x, new_y, new_t_x, new_y, @col_path, dashed)
        @extra_lines << generate_line(new_t_x, new_y, new_t_x, t_y, @col_path ,dashed)
      end

      @height = new_y if new_y > @height
    end

    def draw_element(element)
      top  = element.vertical_indent

      left   = element.horizontal_indent
      bottom = top  +$single_line_height
      right  = left + element.content_width

      txt_pos = left + (right - left) / 2

      if(element.type == ETYPE_LEAF)
        col = @col_leaf
      else
        col = @col_node
      end

      text_data = @text_styles.sub(/COLOR/, col)
      text_data = text_data.sub(/fontsize/, @fontsize.to_s + "px;")
      text_x = txt_pos - element.content_width / 2
      text_y = top + $single_line_height - $height_connector_to_text
      text_data  = text_data.sub(/X_VALUE/, text_x.to_s)
      text_data  = text_data.sub(/Y_VALUE/, text_y.to_s)
      new_text = ""
      this_x = 0
      this_y = 0
      bc = {:x => text_x - $h_gap_between_nodes / 2 , :y => top, :width => element.content_width + $h_gap_between_nodes, :height => nil}
      element.content.each_with_index do |l, idx|
        case l[:type]
        when :border, :bborder
          x1 = text_x
          if idx == 0
            text_y -= l[:height]
          elsif
            text_y += l[:height]
          end
          y1 = text_y - $single_line_height / 8
          x2 = text_x + element.content_width
          y2 = y1
          this_width = x2 - x1
          case l[:type]
          when :border
            stroke_width = FONT_SCALING
          when :bborder
            stroke_width = FONT_SCALING * 2
          end
          @extra_lines << "<line style=\"stroke:#{col}; stroke-width:#{stroke_width}; \" x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\"></line>"
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
          text_y += l[:elements].map{|e| e[:height]}.max if idx != 0

          l[:elements].each_with_index do |e, idx|
            escaped_text = e[:text].gsub('>', '&gt;').gsub('<', '&lt;');
            decorations = []
            if e[:decoration].include?(:overline)
              decorations << "overline"
            end

            if e[:decoration].include?(:underline)
              decorations << "underline"
            end

            if e[:decoration].include?(:linethrough)
              decorations << "line-through"
            end
            decoration ="text-decoration=\"" + decorations.join(" ") +  "\""

            style = "style=\""
            if e[:decoration].include?(:small)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y - (($single_X_metrics.height - $single_X_metrics.height * SUBSCRIPT_CONST) / 4) + 2
            elsif e[:decoration].include?(:superscript)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y - ($single_X_metrics.height / 4) + 1
            elsif e[:decoration].include?(:subscript)
              style += "font-size: #{(SUBSCRIPT_CONST.to_f * 100).to_i}%; "
              this_y = text_y + 4
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
            when /(?:cjk)/
              fontstyle = "'WenQuanYi Zen Hei', 'Noto Sans', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
            when /(?:sans)/
              if e[:cjk]
                fontstyle = "'Noto Sans JP', 'Noto Sans', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
              else
                fontstyle = "'Noto Sans', 'Noto Sans JP', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', sans-serif"
              end
            when /(?:serif)/
              if e[:cjk]
                fontstyle = "'Noto Serif JP', 'Noto Serif', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', serif"
              else
                fontstyle = "'Noto Serif', 'Noto Serif JP', OpenMoji, 'OpenMoji Color', 'OpenMoji Black', serif"
              end
            end

            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              enc_height = e[:height]
              enc_y = this_y - e[:height] * 0.8 + FONT_SCALING

              if e[:text].size == 1
                enc_width = e[:width]
                enc_x = this_x
              else
                enc_width = e[:width]
                enc_x = this_x
              end

              if e[:decoration].include?(:hatched)
                case element.type
                when ETYPE_LEAF
                  if @color
                    fill = "url(#hatchForLeaf)"
                  else
                    fill = "url(#hatchBlack)"
                  end
                when ETYPE_NODE
                  if @color
                    fill = "url(#hatchForNode)"
                  else
                    fill = "url(#hatchBlack)"
                  end
                end
              else
                fill = "none"
              end

              enc = nil
              bar = nil

              if e[:decoration].include?(:bstroke)
                stroke_width = FONT_SCALING * 2.5
              else
                stroke_width = FONT_SCALING
              end

              if e[:decoration].include?(:box)
                enc = "<rect style='stroke: #{col}; stroke-width:#{stroke_width};'
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
                bar = "<line style='stroke:#{col}; stroke-width:#{stroke_width};' x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}'></line>\n"
                @extra_lines << bar

                if e[:decoration].include?(:arrow_to_l)
                  l_arrowhead = "<polyline stroke-linejoin='bevel' fill='none' stroke='#{col}' stroke-width='#{stroke_width}' points='#{x1 + ar_hwidth},#{y1 + ar_hwidth / 2} #{x1},#{y1} #{x1 + ar_hwidth},#{y1 - ar_hwidth / 2}' />\n"
                  @extra_lines << l_arrowhead
                end

                if e[:decoration].include?(:arrow_to_r)
                  r_arrowhead = "<polyline stroke-linejoin='bevel' fill='none' stroke='#{col}' stroke-width='#{stroke_width}' points='#{x2 - ar_hwidth},#{y2 - ar_hwidth / 2} #{x2},#{y2} #{x2 - ar_hwidth},#{y2 + ar_hwidth / 2}' />\n"
                  @extra_lines << r_arrowhead
                end


              end

              @extra_lines << enc if enc

              if e[:text].size == 1
                this_x += (e[:height] - e[:content_width]) / 2
              else
                this_x += $width_half_X / 2
              end
              new_text << set_tspan(this_x, this_y, style, decoration, fontstyle, escaped_text)
              if e[:text].size == 1
                this_x += e[:content_width]
                this_x += (e[:height] - e[:content_width]) / 2
              else
                this_x += e[:content_width]
                this_x += $width_half_X / 2
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
      bc[:y] = bc[:y] + $height_connector_to_text * 3 / 4
      bc[:height] = text_y - bc[:y] + $height_connector_to_text
      if element.enclosure == :brackets
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x] + $h_gap_between_nodes / 2, bc[:y], col)
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x], bc[:y] + bc[:height], col)
        @extra_lines << generate_line(bc[:x], bc[:y] + bc[:height], bc[:x] + $h_gap_between_nodes / 2, bc[:y] + bc[:height], col)
        @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width] - $h_gap_between_nodes / 2, bc[:y], col)
        @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width], bc[:y] + bc[:height], col)
        @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y] + bc[:height], bc[:x] + bc[:width] - $h_gap_between_nodes / 2, bc[:y] + bc[:height], col)
      elsif element.enclosure == :rectangle
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x] + bc[:width], bc[:y], col)
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x], bc[:y] + bc[:height], col)
        @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width], bc[:y] + bc[:height], col)
        @extra_lines << generate_line(bc[:x], bc[:y] + bc[:height], bc[:x] + bc[:width], bc[:y] + bc[:height], col)
      elsif element.enclosure == :brectangle
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x] + bc[:width], bc[:y], col, false, false, 2)
        @extra_lines << generate_line(bc[:x], bc[:y], bc[:x], bc[:y] + bc[:height], col, false, false, 2)
        @extra_lines << generate_line(bc[:x] + bc[:width], bc[:y], bc[:x] + bc[:width], bc[:y] + bc[:height], col, false, false, 2)
        @extra_lines << generate_line(bc[:x], bc[:y] + bc[:height], bc[:x] + bc[:width], bc[:y] + bc[:height], col, false, false, 2)
      end

      element.content_height = bc[:height]
      @tree_data += text_data.sub(/CONTENT/, new_text)
    end

    def set_tspan(this_x, this_y, style, decoration, fontstyle, text)
      text.gsub!(/￭+/) do |x|
        num_spaces = x.size
        "<tspan style='fill:none;'>" + "￭" * num_spaces + "</tspan>"
      end
      "<tspan x='#{this_x}' y='#{this_y}' #{style} #{decoration} font-family=\"#{fontstyle}\">#{text}</tspan>\n"
    end


    def draw_paths
      rockbottom = 0
      path_pool_target = {}
      path_pool_other = {}
      path_pool_source = {}
      path_flags = []
      # elist = @element_list.get_elements.reverse
      elist = @element_list.get_elements

      elist.each do |element|
        x1 = element.horizontal_indent + element.content_width / 2
        y1 = element.vertical_indent + element.content_height
        y1 += $height_connector_to_text if element.enclosure != :none
        et = element.path
        et.each do |tr|
          if /\A>(\d+)\z/ =~ tr
            tr = $1
            if path_pool_target[tr]
              path_pool_target[tr] << [x1, y1]
            else
              path_pool_target[tr] = [[x1, y1]]
            end
          elsif path_pool_source[tr]
            if path_pool_other[tr]
              path_pool_other[tr] << [x1, y1]
            else
              path_pool_other[tr] = [[x1, y1]]
            end
          else
            path_pool_source[tr] = [x1, y1]
          end
          path_flags << tr
          if path_flags.tally.any?{|k, v| v > 2}
            raise RSTError, "Error: input text contains a path having more than two ends:\n > #{tr}"
          end
        end
      end

      path_flags.tally.each do |k, v|
        if v == 1
          raise RSTError, "Error: input text contains a path having only one end:\n > #{k}"
        end
      end

      paths = []
      path_pool_source.each do |k, v|
        path_flags.delete(k)
        if targets = path_pool_target[k]
          targets.each do |t|
            paths << {x1: v[0], y1: v[1], x2: t[0], y2: t[1], arrow: :single}
          end
        elsif others = path_pool_other[k]
          others.each do |t|
            paths << {x1: v[0], y1: v[1], x2: t[0], y2: t[1], arrow: :none}
          end
        end
      end

      path_flags.uniq.each do |k|
        targets = path_pool_target[k]
        fst = targets.shift
        targets.each do |t|
          paths << {x1: fst[0], y1: fst[1], x2: t[0], y2: t[1], arrow: :double}
        end
      end

      paths.each do |t|
        draw_a_path(t[:x1], t[:y1] + $height_connector_to_text / 2,
                    t[:x2], t[:y2] + $height_connector_to_text / 2,
                    t[:arrow])
      end

      paths.size
    end

    def generate_line(x1, y1, x2, y2, col, dashed = false, arrow = false, stroke_width = 1)
      if arrow
        string = "marker-end='url(#arrow)' "
      else
        string = ""
      end
      dasharray = dashed ? "stroke-dasharray='8 8'" : ""
      swidth = FONT_SCALING * stroke_width

      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' style='fill: none; stroke: #{col}; stroke-width:#{swidth}' #{dasharray} #{string}/>"
    end

    # Draw a line between child/parent elements
    def line_to_parent(parent, child)
      if (child.horizontal_indent == 0 )
        return
      end

      if @polyline
        chi_x = child.horizontal_indent + child.content_width / 2
        chi_y = child.vertical_indent + $height_connector_to_text / 2

        par_x = parent.horizontal_indent + parent.content_width / 2
        par_y = parent.vertical_indent + parent.content_height + $height_connector_to_text

        mid_x1 = chi_x
        mid_y1 = par_y  + (chi_y - par_y) / 2

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
        y1 = child.vertical_indent + $height_connector_to_text / 2
        x2 = parent.horizontal_indent + parent.content_width / 2
        y2 = parent.vertical_indent + parent.content_height + $height_connector_to_text

        line_data   = @line_styles.sub(/X1/, x1.to_s)
        line_data   = line_data.sub(/Y1/, y1.to_s)
        line_data   = line_data.sub(/X2/, x2.to_s)
        @tree_data += line_data.sub(/Y2/, y2.to_s)
      end
    end

    # Draw a triangle between child/parent elements
    def triangle_to_parent(parent, child)
      if (child.horizontal_indent == 0)
        return
      end

      x1 = child.horizontal_indent
      y1 = child.vertical_indent + $height_connector_to_text / 2
      x2 = child.horizontal_indent + child.content_width
      y2 = child.vertical_indent + $height_connector_to_text / 2
      x3 = parent.horizontal_indent + parent.content_width / 2
      y3 = parent.vertical_indent + parent.content_height + $height_connector_to_text

      polygon_data = @polygon_styles.sub(/X1/, x1.to_s)
      polygon_data = polygon_data.sub(/Y1/, y1.to_s)
      polygon_data = polygon_data.sub(/X2/, x2.to_s)
      polygon_data = polygon_data.sub(/Y2/, y2.to_s)
      polygon_data = polygon_data.sub(/X3/, x3.to_s)
      @tree_data  += polygon_data.sub(/Y3/, y3.to_s)
    end
  end
end
