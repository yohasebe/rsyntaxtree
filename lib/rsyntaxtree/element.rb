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

class Element

    attr_accessor :id, :parent, :type, :content, :level, :width, :indent, :triangle
    def initialize(id = 0, parent = 0, content = "", level = 0, type = ETYPE_LEAF)
      @id = id                 # Unique element id
      @parent = parent         # Parent element id
      @type = type             # Element type
      @level = level           # Element level in the tree (0=top etc...)
      @width = 0               # Width of the element in pixels
      @indent = 0              # Drawing offset
      content = content.strip
      if /\A.+\^\z/ =~ content
        @content = content.gsub("^"){""} # The actual element content
        @triangle = true # draw triangle instead of stright bar when in auto mode
      else
        @content = content.gsub("^"){""}.strip # The actual element content
        @triangle = false # draw triangle instead of stright bar when in auto mode
      end
      # workaround to save "[A [B [C] [D] ] [E [F] [G [H] [J] ] ] ]"
    end

    # Debug helper function
    def dump
      printf( "ID      : %d\n", @id );
      printf( "Parent  : %d\n", @parent );
      printf( "Level   : %d\n", @level );
      printf( "Type    : %d\n", @type );
      printf( "Width   : %d\n", @width );
      printf( "Indent  : %d\n", @indent );
      printf( "Content : %s\n\n", @content );
    end

end
