# frozen_string_literal: true

#==========================
# elementlist.rb
#==========================
#
# Contains a list of unordered tree elements with a defined parent
# Copyright (c) 2007-2023 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative "element"

module RSyntaxTree
  class ElementList
    attr_accessor :elements, :iterator

    def initialize
      @elements = []
      @iterator = -1 # Iterator index (used for get_first / get_next)
    end

    def set_hierarchy
      @elements.each do |e|
        get_id(e.parent).add_child(e.id) unless e.parent.zero?
      end
    end

    def add(element)
      @elements << element
      return if element.parent.zero?

      parent = get_id(element.parent)
      parent.type = ETYPE_NODE
    end

    def get_first
      return nil if @elements.length.empty?

      @iterator = 0
      @elements[@iterator]
    end

    def get_next
      @iterator += 1
      return @elements[@iterator] if @elements[@iterator]

      nil
    end

    def get_id(id)
      @elements.each do |element|
        return element if element.id == id
      end
      nil
    end

    def get_elements
      @elements
    end

    def get_child_count(id)
      get_children(id).length
    end

    def get_children(id)
      children = []
      @elements.each do |element|
        children << element.id if element.parent == id
      end
      children
    end

    def get_element_width(id)
      element = get_id(id)
      return element.width if element

      -1;
    end

    def set_element_width(id, width)
      element = get_id(id)
      element.width = width if element
    end

    def get_indent(id)
      element = get_id(id)
      return element.indent if element

      -1
    end

    def set_indent(id, indent)
      element = get_id(id)
      element.indent = indent if element
    end

    def get_level_height
      maxlevel = 0
      @elements.each do |element|
        level = element.level
        maxlevel = level if level > maxlevel
      end
      maxlevel + 1
    end
  end
end
