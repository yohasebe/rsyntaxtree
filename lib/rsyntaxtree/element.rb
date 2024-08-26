# frozen_string_literal: true

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
# Copyright (c) 2007-2024 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative "markup_parser"
require_relative "utils"

module RSyntaxTree
  class Element
    attr_accessor :id, :parent, :type, :level, :width, :height, :content, :content_width, :content_height, :horizontal_indent, :vertical_indent, :triangle, :enclosure, :children, :font, :fontsize, :contains_phrase, :path

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

      @contains_phrase = false
      setup
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
            e[:text] = text.gsub(" ", WHITESPACE_BLOCK).gsub(">", '&#62;').gsub("<", '&#60;')

            @contains_phrase = true if text.include?(" ")
            decoration = e[:decoration]
            fontsize = decoration.include?(:small) ? @fontsize * SUBSCRIPT_CONST : @fontsize
            fontsize = decoration.include?(:subscript) || decoration.include?(:superscript) ? fontsize * SUBSCRIPT_CONST : fontsize
            style    = decoration.include?(:italic) || decoration.include?(:bolditalic) ? :italic : :normal
            weight   = decoration.include?(:bold) || decoration.include?(:bolditalic) ? :bold : :normal
            font = if decoration.include? :bolditalic
                     @fontset[:bolditalic]
                   elsif decoration.include? :bold
                     @fontset[:bold]
                   elsif decoration.include? :italic
                     @fontset[:italic]
                   else
                     @fontset[:normal]
                   end

            standard_metrics = FontMetrics.get_metrics('X', @fontset[:normal], fontsize, :normal, :normal)

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
                this_font = if seg[:type] == :emoji
                              @fontset[:emoji]
                            else
                              font
                            end
                metrics = FontMetrics.get_metrics(ch, this_font, fontsize, style, weight)
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
              e[:content_width] = width
              width += if e[:text].size == 1
                         height - width
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
      @content_width = total_width
      @content_height = total_height
    end

    def add_child(child_id)
      @children << child_id
    end
  end
end
