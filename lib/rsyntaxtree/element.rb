# frozen_string_literal: true

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative "markup_parser"
require_relative "utils"

module RSyntaxTree
  class Element
    attr_accessor :id, :parent, :type, :level, :width, :height, :content, :content_width, :content_height, :horizontal_indent, :vertical_indent, :triangle, :enclosure, :children, :font, :fontsize, :contains_phrase, :path, :color, :raw_content, :region, :region_color

    def initialize(id, parent, content, level, fontset, fontsize, global)
      @global = global
      @type = ETYPE_LEAF
      @id = id                 # Unique element id
      @parent = parent         # Parent element id
      @children = []           # Child element ids
      @level = level           # Element level in the tree (0=top etc...)
      @width = 0               # Width of the part of the tree including itself and it governs
      @content_width = 0       # Width of the content
      @horizontal_indent = 0   # Drawing offset
      @vertical_indent = 0     # Drawing offset
      content = content.strip

      @path = if /.+?\^?((?:\+-?>?<?\d+)+)\^?\z/m =~ content
                $1.sub(/\A\+/, "").split("+")
              else
                []
              end

      @fontset = fontset
      @fontsize = fontsize
      @raw_content = content.sub(/\^?(?:\+-?>?<?\d+)+\^?\z/, '')

      parsed = Markup.parse(content)

      if parsed[:status] == :success
        results = parsed[:results]
      else
        error_text = +"Error: input text contains an invalid string"
        error_text += "\n > " + content
        raise RSTError, error_text
      end
      @content = results[:contents]
      @paths = results[:paths]
      @enclosure = results[:enclosure]
      @triangle = results[:triangle]
      @color = results[:color]
      @region = results[:region]
      @region_color = results[:region_color]

      @contains_phrase = false
      setup
    end

    # True when the element renders no visible label — its text consists
    # only of whitespace placeholders (from `<>`) and it carries no
    # enclosure. Such nodes act as pass-through joints: connectors run
    # continuously through them, which lets a `<>` chain push a leaf down
    # to align with deeper leaves while the line stays unbroken.
    def empty_label?
      return false if @enclosure && @enclosure != :none

      @content.all? do |c|
        c[:type] == :text &&
          c[:elements].all? { |e| e[:text].gsub(WHITESPACE_BLOCK, "").strip.empty? }
      end
    end

    def setup
      layout = measure_lines(@content)
      @content_width = layout[:width]
      @content_height = layout[:height]
    end

    # Measures a list of label lines, filling in the width and height of every
    # element and aligning the columns that \t marks. A nested matrix runs
    # through here again, which is what lets a feature structure hold another.
    def measure_lines(lines)
      total_width = 0
      total_height = 0
      one_bvm_given = false
      lines.each do |content|
        content_width = 0
        case content[:type]
        when :border, :bborder
          height = @global[:single_line_height] / 2
          content[:height] = height
          total_height += height
        when :text
          row_width = 0
          elements_height = []
          content[:elements].each do |e|
            # A nested matrix is measured by the same code one level down, and
            # reports the size of the block it will occupy in this row: its own
            # content plus the brackets drawn around it.
            if e[:decoration].include?(:matrix)
              inner = measure_lines(e[:matrix])
              e[:matrix_width] = inner[:width]
              e[:matrix_height] = inner[:height]
              e[:width] = inner[:width] + matrix_bracket_room * 2
              e[:height] = inner[:height] + matrix_vertical_room * 2
              elements_height << e[:height]
              row_width += e[:width]
              next
            end

            text = e[:text]
            # Handle escaped square brackets
            text = text.gsub('\\[', '[')
                      .gsub('\\]', ']')
            # Typographic apostrophe: render a straight ASCII apostrophe (U+0027)
            # as a curly apostrophe (U+2019) for smarter typography, e.g. the
            # X-bar prime in "T'". Applied before metrics so the measured glyph
            # matches the rendered one.
            text = text.gsub("'", "’")
            e[:text] = text.gsub(" ", WHITESPACE_BLOCK)
                          .gsub(">", '&#62;')
                          .gsub("<", '&#60;')

            @contains_phrase = true if text.include?(" ")
            decoration = e[:decoration]
            fontsize = decoration.include?(:small) ? @fontsize * SUBSCRIPT_CONST : @fontsize
            fontsize = decoration.include?(:subscript) || decoration.include?(:superscript) ? fontsize * SUBSCRIPT_CONST : fontsize
            style    = decoration.include?(:italic) || decoration.include?(:bolditalic) ? :italic : :normal
            weight   = decoration.include?(:bold) || decoration.include?(:bolditalic) ? :bold : :normal
            # Bold/italic are expressed through Pango's style/weight parameters,
            # so a single family list is measured for every decoration.
            font = @fontset[:family]

            standard_metrics = FontMetrics.get_metrics('X', font, fontsize, :normal, :normal)

            height = standard_metrics.height
            if /\A[<>]+\z/ =~ text
              width = standard_metrics.width * text.size / 2
            elsif text.contains_emoji?
              segments = text.split_by_emoji
              width = 0
              segments.each do |seg|
                ch = if /\s/ =~ seg[:char]
                       't'
                     else
                       seg[:char]
                     end
                # Emoji segments are measured with the same family list;
                # fontconfig/coretext falls back to an emoji font.
                metrics = FontMetrics.get_metrics(ch, font, fontsize, style, weight)
                width += metrics.width
              end
            else
              text.gsub!("\\\\", 'i')
              text.gsub!("\\", "")
              text.gsub!(" ", "x")
              text.gsub!("%", "X")
              metrics = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              width = metrics.width
            end

            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              # One size and one height for every enclosure in a figure, so a
              # hatched circle, an empty box and a lettered tag line up and
              # share a diameter. The line's rhythm used to set the size, which
              # left a box standing a head taller than the numeral inside;
              # centring each shape on its own glyph instead made the box
              # around 's' sit lower than the one around 'G'.
              #
              # The shape is centred on a capital — the half-way point of the
              # letters it will usually hold — and drawn at ENCLOSURE_SIZE,
              # which is wide enough that a descender still clears the bottom.
              # Centring on the whole cap-to-descender band instead would sit
              # the shape low around the digits and capitals that fill most
              # tags, since those never reach below the baseline. It grows past
              # ENCLOSURE_SIZE only for content that will not fit.
              band = FontMetrics.get_metrics("Xg", font, fontsize, :normal, :normal)
              descender = band.ink_height - band.ink_above
              centre = standard_metrics.ink_above / 2.0

              ink = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              ink_height = ink.ink_height.to_f
              # Deep enough for a descender, so the one letter in a hundred that
              # has one does not get a taller box than its neighbours.
              half = [fontsize * ENCLOSURE_SIZE / 2.0, centre + descender].max

              if ink_height.positive?
                reach = [ink.ink_above - centre, centre - (ink.ink_above - ink_height)].max
                half = reach + fontsize * ENCLOSURE_PADDING if reach > half
              end

              e[:enc_height] = half * 2
              e[:enc_above] = centre + half

              e[:content_width] = width
              width += if e[:text].size == 1
                        [e[:enc_height] - width, 0].max
                      else
                        @global[:width_half_x]
                      end
            end

            if e[:decoration].include?(:whitespace)
              width = @global[:width_half_x] / 2 * e[:text].size / 4
              e[:text] = ""
            end

            e[:height] = height

            if one_bvm_given
              elements_height << height
            else
              one_bvm_given = true
              elements_height << height + @global[:box_vertical_margin]
            end

            e[:width] = width
            row_width += width
          end

          total_height += elements_height.max
          content_width += row_width
        end
        total_width = content_width if total_width < content_width
      end
      { width: align_columns(lines, total_width), height: total_height }
    end

    def add_child(child_id)
      @children << child_id
    end

    # Horizontal room a nested matrix needs on each side for its bracket and
    # the air around it.
    def matrix_bracket_room
      @global[:width_half_x] * MATRIX_BRACKET_ROOM
    end

    # Vertical room a nested matrix keeps between itself and the rows above and
    # below it.
    def matrix_vertical_room
      @global[:single_x_metrics].height * MATRIX_VERTICAL_ROOM
    end

    private

    # Lines cut at \t are laid out in columns: every column is as wide as its
    # widest cell, so attributes line up down the left and their values down
    # the right, which is what an attribute-value matrix is. The separator
    # element carries the padding that takes its cell out to the column width,
    # and the widest line decides the label's width.
    #
    # Returns the label width, unchanged when no line has a separator.
    def align_columns(lines, fallback_width)
      rows = lines.select { |c| c[:type] == :text }
                  .map { |c| split_into_cells(c[:elements]) }
      return fallback_width unless rows.any? { |cells| cells.size > 1 }

      columns = rows.map(&:size).max
      widths = Array.new(columns) do |i|
        rows.filter_map { |cells| cells[i]&.sum { |e| e[:width] } }.max || 0
      end
      gutter = @global[:width_half_x]

      rows.each do |cells|
        cells.each_with_index do |cell, i|
          separator = cell.find { |e| e[:decoration].include?(:tabstop) }
          next unless separator

          used = cell.sum { |e| e[:width] }
          separator[:width] = widths[i] - used + gutter
        end
      end

      widths.sum + gutter * (columns - 1)
    end

    # Each cell keeps the separator that closes it, so the padding has
    # something to sit on.
    def split_into_cells(elements)
      cells = [[]]
      elements.each do |e|
        cells.last << e
        cells << [] if e[:decoration].include?(:tabstop)
      end
      cells.pop if cells.last.empty?
      cells
    end
  end
end
