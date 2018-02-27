#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# elementlist.rb
#==========================
#
# Contains a list of unordered tree elements with a defined parent
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2018 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'element'

class ElementList

    attr_accessor :elements, :iterator
    def initialize
      @elements = Array.new # The element array
      @iterator = -1 # Iterator index (used for get_first / get_next)
    end
    
    def add(element)
      @elements << element
      if(element.parent != 0)
        parent = get_id(element.parent)
        parent.type = ETYPE_NODE
      end
    end

    def get_first
      if(@elements.length == 0)
        return nil
      else
        @iterator = 0
        return @elements[@iterator]
      end
    end

    def get_next
        @iterator += 1
        if @elements[@iterator]
          return @elements[@iterator]
        else
          return nil
        end
    end

    def get_id(id)
      @elements.each do |element|
        if(element.id == id)
          return element 
        end
      end  
      return nil;
    end

    def get_elements
      @elements
    end

    def get_child_count(id)
      get_children(id).length
    end

    def get_children(id)
      children = Array.new
      @elements.each do |element|
        if(element.parent == id)
          children << element.id
        end
      end
      children
    end

    def get_element_width(id)
      element = get_id(id)
      if element
        return element.width
      else
        return -1;
      end
    end

    def set_element_width(id, width)
      element = get_id(id)
      if element
        element.width = width
      end
    end

    def get_indent(id)
      element = get_id(id)
      if element
        return element.indent
      else
        return -1
      end  
    end

    def set_indent(id, indent)
      element = get_id(id)
      if element
        element.indent = indent
      end
    end

    def get_level_height
      maxlevel = 0
      @elements.each do |element|
        level = element.level
        if(level > maxlevel)
          maxlevel = level
        end
      end
      return maxlevel + 1;
    end
    
end
    
