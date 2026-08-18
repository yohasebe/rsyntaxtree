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
      total_width = 0
      total_height = 0
      one_bvm_given = false
      @content.each do |content|
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

            # The following is unchanged
            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              # Size the enclosure to the marks it encloses, not to the line's
              # rhythm: the rhythm leaves room for ascenders and descenders no
              # digit uses, so a box drawn to it stands a head taller than the
              # tag inside. Measuring the ink keeps a tag snug and still lets a
              # full-height glyph — kana, an emoji — have the room it needs.
              # A capital sets the floor, so boxes around 's' and around 'G' come
              # out the same height and a row of tags reads as a row; a taller
              # glyph than that — kana, an emoji — pushes the shape open.
              ink = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              padding = height * ENCLOSURE_PADDING
              if ink.ink_height.to_f.positive?
                above = [ink.ink_above, standard_metrics.ink_above].max
                below = [ink.ink_height - ink.ink_above, standard_metrics.ink_height - standard_metrics.ink_above].max
                span = above + below
                # A circle around a single character has to clear the corners of
                # the glyph, not just its height: a letter that fits a square of
                # this side pokes out of the circle drawn inside it. Take the
                # diagonal. Longer text sits in a stadium, whose rounded ends
                # already leave the corners room, so height alone will do.
                if e[:decoration].include?(:circle) && e[:text].size == 1
                  span = Math.sqrt(span**2 + width**2)
                  above += (span - (above + below)) / 2
                end
                e[:enc_height] = span + padding * 2
                e[:enc_above] = above + padding
              else
                # Bars and other blank-texted shapes have no ink to measure.
                e[:enc_height] = height
                e[:enc_above] = height * 0.8
              end

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
      total_width = align_columns(total_width)
      @content_width = total_width
      @content_height = total_height
    end

    def add_child(child_id)
      @children << child_id
    end

    private

    # Lines cut at \t are laid out in columns: every column is as wide as its
    # widest cell, so attributes line up down the left and their values down
    # the right, which is what an attribute-value matrix is. The separator
    # element carries the padding that takes its cell out to the column width,
    # and the widest line decides the label's width.
    #
    # Returns the label width, unchanged when no line has a separator.
    def align_columns(fallback_width)
      rows = @content.select { |c| c[:type] == :text }
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
