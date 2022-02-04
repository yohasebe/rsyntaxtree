#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>

require "markup_parser"
require 'utils'

module RSyntaxTree
  class Element

    attr_accessor :id,
      :parent, :type, :level,
      :width, :height,
      :content, :content_width, :content_height,
      :horizontal_indent, :vertical_indent,
      :triangle, :enclosure, :children, :parent,
      :font, :fontsize, :contains_phrase,
      :path

    def initialize(id, parent, content, level, fontset, fontsize)
      @type = ETYPE_LEAF
      @id = id                 # Unique element id
      @parent = parent         # Parent element id
      @children = []           # Child element ids
      @type = type             # Element type
      @level = level           # Element level in the tree (0=top etc...)
      @width = 0               # Width of the part of the tree including itself and it governs
      @content_width = 0       # Width of the content
      @horizontal_indent = 0   # Drawing offset
      @vertical_indent = 0     # Drawing offset
      content = content.strip

      if /.+?\^?((?:\+\>?\d+)+)\^?\z/m =~ content
        @path = $1.sub(/\A\+/, "").split("+")
      else
        @path = []
      end

      @fontset = fontset
      @fontsize = fontsize

      parsed = Markup.parse(content)

      if parsed[:status] == :success
        results = parsed[:results]
      else
        error_text = "Error: input text contains an invalid string"
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
      @content.each_with_index do |content, idx|
        content_width = 0
        case content[:type]
        when :border, :bborder
          height = $single_line_height / 2
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
            fontsize = decoration.include?(:small) || decoration.include?(:small) ? @fontsize * SUBSCRIPT_CONST : @fontsize
            fontsize = decoration.include?(:subscript) || decoration.include?(:superscript)  ? fontsize * SUBSCRIPT_CONST : fontsize
            style    = decoration.include?(:italic) || decoration.include?(:bolditalic) ? :italic : :normal
            weight   = decoration.include?(:bold) || decoration.include?(:bolditalic) ? :bold : :normal

            # e[:cjk] = false
            # if e[:decoration].include?(:math)
            #   font = @fontset[:math]
            # elsif text.contains_cjk?
            #   font = @fontset[:cjk]
            #   e[:cjk] = true
            # elsif decoration.include? :bolditalic
            if decoration.include? :bolditalic
              font = @fontset[:bolditalic]
            elsif decoration.include? :bold
              font = @fontset[:bold]
            elsif decoration.include? :italic
              font = @fontset[:italic]
            else
              font = @fontset[:normal]
            end

            standard_metrics = FontMetrics.get_metrics('X', @fontset[:normal], fontsize, :normal, :normal)
            height = standard_metrics.height
            if /\A[\<\>]+\z/ =~ text
              width = standard_metrics.width * text.size / 2
            elsif text.contains_emoji?
              segments = text.split_by_emoji
              width = 0
              segments.each do |seg|
                if /\s/ =~ seg[:char]
                  ch = 't'
                else
                  ch = seg[:char]
                end
                if seg[:type] == :emoji
                  this_font = @fontset[:emoji]
                  metrics = FontMetrics.get_metrics(ch, this_font, fontsize, style, weight)
                  width += metrics.width
                else
                  this_font = font
                  metrics = FontMetrics.get_metrics(ch, this_font, fontsize, style, weight)
                  width += metrics.width
                end
              end
            else
              text.gsub!("\\\\", 'i')
              text.gsub!("\\", "")
              text.gsub!(" ", "x")
              metrics = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              width = metrics.width
            end

            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              if e[:text].size == 1
                e[:content_width] = width
                width += (height - width)
              else
                e[:content_width] = width
                width += $width_half_X
              end
            end

            if e[:decoration].include?(:whitespace)
              width = $width_half_X / 2 * e[:text].size / 4
              e[:text] = ""
            end

            e[:height] = height
            elements_height << height + $box_vertical_margin / 2

            e[:width] = width
            row_width += width
          end

          if @enclosure != :none
            total_height += (elements_height.max + $height_connector_to_text)
          else
            total_height += elements_height.max
          end
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
