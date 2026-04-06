# frozen_string_literal: true

#==========================
# lsif_graph.rb
#==========================
#
# Generates LSIF (Linguistic Structure Interchange Format) JSON output.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require 'json'
require_relative 'base_graph'
require_relative 'utils'

module RSyntaxTree
  class LsifGraph < BaseGraph
    attr_accessor :width, :height

    def initialize(element_list, params, global)
      super(element_list, params, global)
      @height = 0
      @width = 0
      @nodes = []
      @edges = []
      @paths_data = []
      @params = params
      @fontsize = params[:fontsize]
      @color = params[:color]
      @polyline = params[:polyline]
      @visited_x = {}
      @global = global
    end

    def lsif_data
      metrics = parse_list
      @width = metrics[:width] + @global[:h_gap_between_nodes] * 2
      @height = metrics[:height] + @global[:height_connector_to_text] / 2
      build_json
    end

    # Override rendering methods to collect structural data

    def draw_element(element)
      # Track height the same way SVGGraph does
      top = element.vertical_indent
      text_y = top + @global[:single_line_height] - @global[:height_connector_to_text]
      element.content.each_with_index do |l, idx|
        case l[:type]
        when :border, :bborder
          text_y += idx.zero? ? -l[:height] : l[:height]
        when :text
          text_y += l[:elements].map { |e| e[:height] }.max if idx != 0
        end
        @height = text_y if text_y > @height
      end

      @nodes << build_node(element)
    end

    def line_to_parent(parent, child)
      @edges << { from: parent.id, to: child.id, type: "dominance", connector: "line" }
    end

    def triangle_to_parent(parent, child)
      @edges << { from: parent.id, to: child.id, type: "dominance", connector: "triangle" }
    end

    # Override draw_connector to capture all edges including "none" connector
    def draw_connector(id = 1)
      parent = @element_list.get_id(id)
      children = parent.children.map { |c| @element_list.get_id(c) }

      if children.size == 1
        child = children[0]
        case @leafstyle
        when "auto"
          if parent.triangle || child.contains_phrase
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "bar"
          if parent.triangle
            triangle_to_parent(parent, child)
          else
            line_to_parent(parent, child)
          end
        when "nothing", "none"
          if parent.triangle
            triangle_to_parent(parent, child)
          elsif ETYPE_LEAF != child.type
            line_to_parent(parent, child)
          else
            @edges << { from: parent.id, to: child.id, type: "dominance", connector: "none" }
          end
        end
      else
        children.each do |child|
          line_to_parent(parent, child)
        end
      end

      parent.children.each { |c| draw_connector(c) }
    end

    def draw_paths
      path_pool_target = {}
      path_pool_other = {}
      path_pool_source = {}
      path_flags = []
      line_pool = {}
      line_flags = []

      elist = @element_list.get_elements

      elist.each do |element|
        et = element.path
        et.each do |tr|
          if /\A-(>|<)?(\d+)\z/ =~ tr
            arrow = $1
            tr = $2
            if line_pool[tr]
              line_pool[tr] << { id: element.id, arrow: arrow }
            else
              line_pool[tr] = [{ id: element.id, arrow: arrow }]
            end
            line_flags << tr
          elsif /\A(?:>|<)(\d+)\z/ =~ tr
            tr = $1
            if path_pool_target[tr]
              path_pool_target[tr] << element.id
            else
              path_pool_target[tr] = [element.id]
            end
            path_flags << tr
          elsif path_pool_source[tr]
            if path_pool_other[tr]
              path_pool_other[tr] << element.id
            else
              path_pool_other[tr] = [element.id]
            end
            path_flags << tr
          else
            path_pool_source[tr] = element.id
            path_flags << tr
          end
        end
      end

      # Resolve movement paths
      path_pool_source.each do |k, source_id|
        if (target_ids = path_pool_target[k])
          target_ids.each do |target_id|
            @paths_data << { from: source_id, to: target_id, direction: "forward", type: "movement" }
          end
        elsif (other_ids = path_pool_other[k])
          other_ids.each do |other_id|
            @paths_data << { from: source_id, to: other_id, direction: "forward", type: "movement" }
          end
        end
      end

      # Resolve bidirectional paths
      remaining = path_flags.tally.select { |k, v| v >= 2 && !path_pool_source.key?(k) }.keys
      remaining.each do |k|
        targets = path_pool_target[k]
        next if targets.nil? || targets.size < 2

        first = targets[0]
        targets[1..].each do |target_id|
          @paths_data << { from: first, to: target_id, direction: "bidirectional", type: "movement" }
        end
      end

      # Resolve line-type connections
      line_pool.each do |_k, v|
        next unless v.size >= 2

        a = v[0]
        b = v[1]
        direction = if a[:arrow] && b[:arrow]
                      "bidirectional"
                    elsif a[:arrow]
                      "forward"
                    elsif b[:arrow]
                      "forward"
                    else
                      "forward"
                    end
        @paths_data << { from: a[:id], to: b[:id], direction: direction, type: "movement" }
      end
    end

    private

    def build_node(element)
      col = if element.color
              element.color
            elsif element.type == ETYPE_LEAF
              resolve_color(@col_leaf)
            else
              resolve_color(@col_node)
            end

      {
        id: element.id,
        type: element.type == ETYPE_NODE ? "node" : "leaf",
        level: element.level,
        label: build_label(element),
        position: {
          x: element.horizontal_indent.round(1),
          y: element.vertical_indent.round(1),
          content_width: element.content_width.round(1),
          content_height: element.content_height.round(1),
          subtree_width: element.width.round(1)
        },
        style: {
          color: col,
          enclosure: map_enclosure(element.enclosure),
          triangle: element.triangle
        },
        parent: element.parent.zero? ? nil : element.parent,
        children: element.children
      }
    end

    def build_label(element)
      lines = []
      element.content.each do |l|
        next unless l[:type] == :text

        segments = l[:elements].map do |e|
          next if e[:decoration].include?(:whitespace) && e[:text].strip.empty?

          {
            text: e[:text].gsub(WHITESPACE_BLOCK, " ").gsub('&#62;', '>').gsub('&#60;', '<'),
            decorations: e[:decoration].map(&:to_s).reject { |d| d == "whitespace" }
          }
        end.compact
        lines << { segments: segments } unless segments.empty?
      end

      {
        raw: element.raw_content,
        lines: lines
      }
    end

    def map_enclosure(enclosure)
      case enclosure
      when :brackets then "brackets"
      when :rectangle then "rectangle"
      when :brectangle then "bold_rectangle"
      else "none"
      end
    end

    def resolve_color(color)
      color == "black" ? nil : color
    end

    def build_json
      data = {
        lsif: {
          version: "0.2.0",
          generator: "rsyntaxtree #{RSyntaxTree::VERSION}",
          level: "rendered"
        },
        meta: {
          source: {
            format: "rsyntaxtree-bracket",
            input: @params[:data],
            params: {
              font_style: @params[:fontstyle],
              font_size: (@params[:fontsize] / FONT_SCALING).round,
              color: @params[:color],
              connector: @params[:leafstyle],
              connector_height: @params[:vheight],
              line_width: @params[:linewidth],
              symmetrize: @params[:symmetrize],
              polyline: @params[:polyline],
              hide_default_connectors: @params[:hide_default_connectors],
              transparent: @params[:transparent]
            }
          }
        },
        geometry: {
          width: @width.round(1),
          height: @height.round(1),
          direction: @params[:direction] || "ttb"
        },
        nodes: @nodes,
        edges: @edges,
        paths: @paths_data
      }
      JSON.pretty_generate(data)
    end
  end
end
