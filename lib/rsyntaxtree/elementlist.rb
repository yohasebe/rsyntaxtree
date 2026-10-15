# frozen_string_literal: true

#==========================
# elementlist.rb
#==========================
#
# Contains a list of unordered tree elements with a defined parent
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

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
      return nil if @elements.empty?

      @iterator = 0
      @elements[@iterator]
    end

    def get_next
      @iterator += 1
      @elements[@iterator]
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

    # Add invisible `<>` joints to put every leaf at the deepest leaf level.
    def align_leaves(mode, fontset, fontsize, global)
      leaves = @elements.select { |e| e.type == ETYPE_LEAF && e.children.empty? }
      return if leaves.size < 2

      next_id = @elements.map(&:id).max + 1

      if mode == "pad-hi"
        root = @elements.find { |element| element.parent.zero? }
        add_high_joints(root, next_id, fontset, fontsize, global) if root
      else
        deepest = leaves.map(&:level).max

        leaves.each do |leaf|
          joints = deepest - leaf.level
          next unless joints.positive?

          next_id = insert_empty_joints(leaf, joints, next_id, fontset, fontsize, global)
        end
      end

      renumber_preorder
    end

    private

    def add_high_joints(parent, next_id, fontset, fontsize, global)
      children = parent.children.map { |id| get_id(id) }
      heights = children.map { |child| subtree_height(child) }
      deepest = heights.max

      children.zip(heights).each do |child, height|
        joints = deepest - height
        if joints.positive?
          next_id = insert_empty_joints(child, joints, next_id, fontset, fontsize, global)
          shift_subtree_levels(child, joints)
        end
        next_id = add_high_joints(child, next_id, fontset, fontsize, global) unless child.children.empty?
      end
      next_id
    end

    def subtree_height(element)
      return 0 if element.children.empty?

      1 + element.children.map { |id| subtree_height(get_id(id)) }.max
    end

    def insert_empty_joints(child, count, next_id, fontset, fontsize, global)
      parent = get_id(child.parent)
      return next_id unless parent

      count.times do
        joint = Element.new(next_id, parent.id, WHITESPACE_BLOCK, parent.level + 1, fontset, fontsize, global)
        next_id += 1
        @elements << joint
        insert_between(parent, child, joint)
        parent = joint
      end
      next_id
    end

    def shift_subtree_levels(element, count)
      element.level += count
      element.children.each { |id| shift_subtree_levels(get_id(id), count) }
    end

    def insert_between(parent, child, joint)
      parent.children[parent.children.index(child.id)] = joint.id
      joint.add_child(child.id)
      joint.type = ETYPE_NODE
      child.parent = joint.id
    end

    def renumber_preorder
      root = @elements.find { |element| element.parent.zero? }
      return unless root

      ordered = []
      visit = lambda do |element|
        ordered << element
        element.children.each { |id| visit.call(get_id(id)) }
      end
      visit.call(root)

      ids = ordered.each_with_index.to_h { |element, index| [element.id, index + 1] }
      ordered.each do |element|
        element.parent = ids.fetch(element.parent, 0)
        element.children = element.children.map { |id| ids.fetch(id) }
        element.id = ids.fetch(element.id)
      end
      @elements = ordered
    end
  end
end
