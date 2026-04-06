# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "yaml"
require "json"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class LsifGeneratorTest < Minitest::Test
  examples_dir = File.expand_path(File.join(__dir__, "..", "docs", "_examples"))

  # Exclude Test and Error categories
  excluded_categories = ["Test", "Error"]

  Dir.glob("*.md", base: examples_dir).sort.each do |md|
    md_path = File.join(examples_dir, md)
    config = YAML.load_file(md_path)

    next if excluded_categories.include?(config["category"])

    rst = File.read(md_path).scan(/```([^`]+)```/m).last.first
    name = config["name"]

    opts = DEFAULT_OPTS.dup
    config.each do |key, value|
      next if value.to_s == ""

      case key
      when "color"
        opts[:color] = case value
                       when "modern", "on", "true"
                         "modern"
                       when "traditional"
                         "traditional"
                       else
                         "off"
                       end
      when "polyline"
        opts[:polyline] = value
      when "hide_default_connectors"
        opts[:hide_default_connectors] = value
      when "connector_height"
        opts[:vheight] = value
      when "symmetrization"
        opts[:symmetrize] = value
      when "connector"
        opts[:leafstyle] = value
      when "direction"
        opts[:direction] = value
      when "font"
        opts[:fontstyle] = case value
                           when /mono/i
                             "mono"
                           when /sans/i
                             "sans"
                           when /serif/i
                             "serif"
                           when /wqy/i
                             "cjk"
                           else
                             "sans"
                           end
      end
    end

    opts[:data] = rst

    define_method "test_lsif_#{name}" do
      rsg = RSyntaxTree::RSGenerator.new(opts)
      json_str = rsg.draw_lsif
      data = JSON.parse(json_str)

      # Verify top-level structure
      assert data.key?("lsif"), "Missing 'lsif' key"
      assert data.key?("geometry"), "Missing 'geometry' key"
      assert data.key?("nodes"), "Missing 'nodes' key"
      assert data.key?("edges"), "Missing 'edges' key"
      assert data.key?("paths"), "Missing 'paths' key"

      # Verify lsif section
      assert_equal "0.2.0", data["lsif"]["version"]
      assert_equal "rendered", data["lsif"]["level"]
      assert data["lsif"]["generator"].start_with?("rsyntaxtree")

      # Verify geometry
      assert data["geometry"]["width"] > 0, "Width must be positive"
      assert data["geometry"]["height"] > 0, "Height must be positive"
      assert %w[ttb ltr].include?(data["geometry"]["direction"]), "Direction must be ttb or ltr"

      # Verify nodes
      nodes = data["nodes"]
      refute_empty nodes, "Nodes array must not be empty"

      # Verify root node
      root = nodes.find { |n| n["parent"].nil? }
      assert root, "Must have a root node (parent: null)"

      # Verify each node has required fields
      nodes.each do |node|
        assert node.key?("id"), "Node missing 'id'"
        assert %w[node leaf].include?(node["type"]), "Node type must be 'node' or 'leaf'"
        assert node.key?("level"), "Node missing 'level'"
        assert node.key?("label"), "Node missing 'label'"
        assert node["label"].key?("raw"), "Label missing 'raw'"
        assert node["label"].key?("lines"), "Label missing 'lines'"
        assert node.key?("position"), "Node missing 'position'"
        %w[x y content_width content_height subtree_width].each do |field|
          assert node["position"].key?(field), "Position missing '#{field}'"
        end
        assert node.key?("style"), "Node missing 'style'"
        assert node.key?("children"), "Node missing 'children'"
      end

      # Verify parent-child consistency
      node_ids = nodes.map { |n| n["id"] }
      nodes.each do |node|
        node["children"].each do |child_id|
          assert node_ids.include?(child_id), "Child ID #{child_id} not found in nodes"
        end
        if node["parent"]
          assert node_ids.include?(node["parent"]), "Parent ID #{node["parent"]} not found in nodes"
        end
      end

      # Verify edges reference valid node IDs
      data["edges"].each do |edge|
        assert node_ids.include?(edge["from"]), "Edge 'from' ID #{edge["from"]} not found"
        assert node_ids.include?(edge["to"]), "Edge 'to' ID #{edge["to"]} not found"
        assert %w[dominance].include?(edge["type"]), "Edge type must be 'dominance'"
        assert %w[line triangle none].include?(edge["connector"]), "Invalid connector type: #{edge["connector"]}"
      end

      # Verify paths reference valid node IDs
      data["paths"].each do |path|
        assert node_ids.include?(path["from"]), "Path 'from' ID #{path["from"]} not found"
        assert node_ids.include?(path["to"]), "Path 'to' ID #{path["to"]} not found"
        assert %w[forward backward bidirectional].include?(path["direction"]), "Invalid direction"
      end
    end
  end
end

class LsifDirectionTest < Minitest::Test
  def test_lsif_default_direction_is_ttb
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    data = JSON.parse(rsg.draw_lsif)
    assert_equal "ttb", data["geometry"]["direction"]
  end

  def test_lsif_ltr_direction
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    data = JSON.parse(rsg.draw_lsif)
    assert_equal "ltr", data["geometry"]["direction"]
  end

  def test_lsif_ltr_has_valid_structure
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP the cat] [VP [V sat] [PP [P on] [NP the mat]]]]"
    opts[:fontstyle] = "serif"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    data = JSON.parse(rsg.draw_lsif)

    assert data["geometry"]["width"] > 0
    assert data["geometry"]["height"] > 0

    nodes = data["nodes"]
    refute_empty nodes

    root = nodes.find { |n| n["parent"].nil? }
    assert root, "Must have a root node"

    # In LTR, all leaves should be to the right of root
    leaf_xs = nodes.select { |n| n["children"].empty? }.map { |n| n["position"]["x"] }
    root_x = root["position"]["x"]
    assert leaf_xs.all? { |x| x >= root_x }, "In LTR, all leaves should be to the right of root"
  end

  def test_lsif_ltr_nodes_have_valid_positions
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[A [B [D] [E]] [C [F] [G]]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    data = JSON.parse(rsg.draw_lsif)

    data["nodes"].each do |node|
      pos = node["position"]
      assert pos["x"] >= 0, "Node #{node["id"]} x should be >= 0"
      assert pos["y"] >= 0, "Node #{node["id"]} y should be >= 0"
      assert pos["content_width"] > 0, "Node #{node["id"]} content_width should be > 0"
      assert pos["content_height"] > 0, "Node #{node["id"]} content_height should be > 0"
    end
  end

  def test_lsif_ltr_edges_reference_valid_nodes
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    data = JSON.parse(rsg.draw_lsif)

    node_ids = data["nodes"].map { |n| n["id"] }
    data["edges"].each do |edge|
      assert node_ids.include?(edge["from"]), "Edge from #{edge["from"]} not in nodes"
      assert node_ids.include?(edge["to"]), "Edge to #{edge["to"]} not in nodes"
    end
  end
end

class SvgDirectionTest < Minitest::Test
  def test_svg_ltr_generates_valid_xml
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "LTR SVG should be valid XML"
  end

  def test_svg_ltr_with_triangle
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP the cat] [VP sat]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "LTR SVG with triangle should be valid XML"
  end

  def test_svg_ltr_with_polyline
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    opts[:polyline] = "on"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "LTR SVG with polyline should be valid XML"
  end

  def test_svg_ltr_with_bar_style
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    opts[:leafstyle] = "bar"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "LTR SVG with bar style should be valid XML"
  end

  def test_svg_ltr_with_nothing_style
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ltr"
    opts[:leafstyle] = "nothing"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "LTR SVG with nothing style should be valid XML"
  end

  def test_svg_ttb_unchanged_by_ltr_code
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [NP test] [VP works]]"
    opts[:fontstyle] = "sans"
    opts[:direction] = "ttb"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    svg = rsg.draw_svg
    doc = Nokogiri::XML(svg)
    assert doc.errors.empty?, "TTB SVG should still be valid XML"
  end
end
