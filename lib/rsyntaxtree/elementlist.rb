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

    # The edges on the highlighted path, each named by the child it joins to
    # its parent: every step up from the path's two ends to the node where
    # they meet. A path has one number and exactly two ends; anything else is
    # refused, as a movement link with the wrong number of ends is.
    def path_edges
      @path_edges ||= begin
        ends = @elements.reject { |e| e.route.to_a.empty? }
        if ends.empty?
          []
        else
          numbers = ends.flat_map(&:route).uniq
          if numbers.size > 1
            raise RSTError.new(+"Error: input text contains more than one highlighted path:\n > #{numbers.map { |n| "+#{n}" }.join(" ")}",
                               code: :path_numbers, hint: "Only one path can be highlighted; give both of its ends the same '+=N'.",
                               retryable: true)
          end
          if ends.size != 2 || ends.any? { |e| e.route.size > 1 }
            raise RSTError.new(+"Error: input text contains a highlighted path without exactly two ends:\n > +#{numbers.first}",
                               code: :path_ends, hint: "A highlighted path takes two ends: '+=N' on each of two nodes.",
                               retryable: true)
          end

          a, b = ends.map do |e|
            chain = [e.id]
            chain << get_id(chain.last).parent until get_id(chain.last).parent.zero?
            chain
          end
          meet = a.find { |id| b.include?(id) }
          a.take_while { |id| id != meet } + b.take_while { |id| id != meet }
        end
      end
    end

    # Every link and every line connection takes exactly two ends. Checked
    # once, before anything is drawn, so each output refuses the same input.
    def check_link_ends
      links = Hash.new(0)
      lines = Hash.new(0)
      @elements.each do |e|
        e.path.each do |marker|
          if (line = marker[/\A-[<>]?(\d+)\z/, 1])
            lines[line] += 1
          else
            links[marker[/\d+/]] += 1
          end
        end
      end
      over = links.find { |_k, v| v > 2 } || lines.find { |_k, v| v > 2 }
      if over
        raise RSTError.new(+"Error: input text contains a link having more than two ends:\n > #{over.first}",
                           code: :link_multiple_ends, hint: "A link or line takes exactly two ends; check the numbers.",
                           retryable: true)
      end
      if (one = links.find { |_k, v| v == 1 })
        raise RSTError.new(+"Error: input text contains a link having only one end:\n > #{one.first}",
                           code: :link_single_end, hint: "A link takes two ends: one '+N' on each of two nodes.",
                           retryable: true)
      end
      return unless (one = lines.find { |_k, v| v == 1 })

      raise RSTError.new(+"Error: input text contains a line having only one end:\n > #{one.first}",
                         code: :link_single_end, hint: "A line connection takes two ends: '+-N' on each of two nodes.",
                         retryable: true)
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

      if mode == "subtrees"
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
        joint.inserted_joint = true
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
