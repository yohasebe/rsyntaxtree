#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require "markup_parser"
require 'rmagick'
include Magick

class Element

    attr_accessor :id,
      :parent, :type, :level,
      :width, :height,
      :content, :content_width, :content_height,
      :horizontal_indent, :vertical_indent,
      :triangle, :brackets, :children, :parent,
      :font, :fontsize, :contains_phrase

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
      if /\A.+\^\z/m =~ content
        @triangle = true
      else
        @triangle = false
      end
      if /\A\#/m =~ content
        @brackets = true
      else
        @brackets = false
      end
      @fontset = fontset
      @fontsize = fontsize
      @single_line_height = img_get_txt_metrics("X", @fontset[:normal], @fontsize, :normal, :normal).height

      begin
        @content = Markup.parse(content.sub(/\A\#/, "").sub(/\^\z/, ""))
      rescue => e
        puts "Error: Text markup contains invalid sequence: It cannnot be parsed' "
        exit
      end

      @contains_phrase = false
      setup
    end

    def setup
      total_width = 0
      total_height = 0
      @content.each_with_index do |content, idx|
        content_width = 0
        case content[:type]
        when :border
          height = @single_line_height / 2
          content[:height] = height
          total_height += height if idx != 0
        when :blankline
          height = @single_line_height
          content[:height] = height
          total_height += @single_line_height
        when :text
          row_width = 0
          content[:elements].each do |e|
            text = e[:text]
            @contains_phrase = true if text.include?(" ")
            @triangle = true if /^\z/ =~ text
            decoration = e[:decoration]
            fontsize = decoration.include?(:subscript) ||
                       decoration.include?(:superscript) ? @fontsize * SUBSCRIPT_CONST : @fontsize
            style    = decoration.include?(:italic) ||
                       decoration.include?(:bolditalic) ? :italic : :normal
            weight   = decoration.include?(:bold) ||
                       decoration.include?(:bolditalic) ? :bold : :normal

            e[:cjk] = false
            if e[:text].contains_cjk?
              font = @fontset[:cjk]
              e[:cjk] = true
            # elsif e[:text].all_emoji?
            #   font = @fontset[:emoji]
            elsif decoration.include? :bolditalic
              font = @fontset[:bolditalic]
            elsif decoration.include? :bold
              font = @fontset[:bold]
            elsif decoration.include? :italic
              font = @fontset[:italic]
            else
              font = @fontset[:normal]
            end

            # pp e[:text]
            # pp style
            # pp weight
            # pp font

            metrics = img_get_txt_metrics(e[:text], font, fontsize, style, weight)
            height = metrics.height
            e[:height] = height
            total_height += height

            width = metrics.width
            e[:width] = width
            row_width += width
            e[:max_advance] = metrics.max_advance
          end
          content_width += row_width
        end
        total_width = content_width if total_width < content_width
      end
      @content_width = total_width
      @content_height = total_height + @single_line_height / 3.5
    end

    def add_child(child_id)
      @children << child_id
    end

    def img_get_txt_metrics(text, font, fontsize, font_style, font_weight)
      background = Image.new(1, 1)
      gc = Draw.new
      gc.annotate(background, 0, 0, 0, 0, text) do |gc|
        gc.font = font
        gc.font_style = font_style == :italic ? ItalicStyle : NormalStyle
        gc.font_weight = font_weight == :bold ? BoldWeight : NormalWeight
        gc.pointsize = fontsize
        gc.gravity = CenterGravity
        gc.stroke = 'none'
        gc.kerning = 0
        gc.interline_spacing = 0
        gc.interword_spacing = 0
      end
      metrics = gc.get_multiline_type_metrics(background, text)
      return metrics
    end

    # Debug helper function
    def dump
      printf( "ID      : %d\n", @id );
      printf( "Parent  : %d\n", @parent );
      printf( "Level   : %d\n", @level );
      printf( "Width   : %d\n", @width );
      printf( "Indent  : %d\n", @indent );
      printf( "Content : %s\n\n", @content );
    end
end
