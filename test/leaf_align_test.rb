# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"

class LeafAlignTest < Minitest::Test
  TREE = "[S [A a] [B [C b] [D c]]]"

  def document(**options)
    JSON.parse(RSyntaxTree::RSGenerator.new({ data: TREE, format: "json" }.merge(options)).draw_json)
  end

  def svg(**options)
    RSyntaxTree::RSGenerator.new({ data: TREE }.merge(options)).draw_svg
  end

  def leaves(document)
    document.fetch("nodes").select { |node| node["type"] == "leaf" }
  end

  def positions(document, axis)
    leaves(document).map { |node| node.fetch("position").fetch(axis) }
  end

  def test_default_and_explicit_off_are_identical
    assert_equal svg, svg(leaf_align: "off")
  end

  %w[pad-lo pad-hi].each do |mode|
    {
      "ttb" => "y",
      "btt" => "y"
    }.each do |direction, axis|
      define_method "test_#{mode}_#{direction}_aligns_leaf_starts_at_the_far_edge" do
        ordinary = document(direction: direction)
        aligned = document(direction: direction, leaf_align: mode)

        assert_operator positions(ordinary, axis).uniq.size, :>, 1,
                        "the fixture needs leaves at different #{axis} positions"
        assert_equal 1, positions(aligned, axis).uniq.size
        edge = direction == "btt" ? positions(ordinary, axis).min : positions(ordinary, axis).max
        assert_equal edge, positions(aligned, axis).first
      end
    end
  end

  def test_ltr_alignment_levels_leaves
    %w[pad-lo pad-hi].each do |mode|
      [false, true].each do |mirror|
        aligned = document(direction: "ltr", mirror: mirror, leaf_align: mode)
        levels = leaves(aligned).map { |node| node["level"] }

        assert_equal 1, levels.uniq.size, "mode=#{mode}, mirror=#{mirror}"
      end
    end
  end

  def test_alignment_inserts_only_the_needed_invisible_joint
    ordinary = document
    aligned = document(leaf_align: "pad-lo")
    leaf = leaves(aligned).find { |node| node.dig("label", "raw") == "a" }
    joint = aligned.fetch("nodes").find { |node| node["id"] == leaf["parent"] }

    assert_equal ordinary.fetch("nodes").size + 1, aligned.fetch("nodes").size
    assert_equal "node", joint["type"]
    assert_equal [leaf["id"]], joint["children"]
  end

  def test_alignment_keeps_the_input_leaf_order
    data = JSON.parse(
      RSyntaxTree::RSGenerator.new(data: "[S a [B b] c]", format: "json", leaf_align: "pad-lo").draw_json
    )
    ordered = leaves(data).sort_by { |node| node.dig("position", "x") }
                         .map { |node| node.dig("label", "raw") }

    assert_equal %w[a b c], ordered
  end

  def test_one_leaf_tree_is_not_moved
    plain = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S a]", format: "json").draw_json)
    aligned = JSON.parse(RSyntaxTree::RSGenerator.new(data: "[S a]", format: "json", leaf_align: "pad-lo").draw_json)

    assert_equal leaves(plain).map { |node| node["position"] },
                 leaves(aligned).map { |node| node["position"] }
  end

  def test_derivations_keep_their_existing_leaf_rows
    options = { direction: "btt", derivation: "on", leafstyle: "nothing" }
    plain = document(**options)
    aligned = document(**options, leaf_align: "pad-lo")

    assert_equal leaves(plain).map { |node| node["position"] },
                 leaves(aligned).map { |node| node["position"] }
  end

  def test_json_records_the_resolved_option
    assert_equal "pad-lo", document(leaf_align: "on").dig("meta", "source", "params", "leaf_align")
    assert_equal "pad-lo", document(leaf_align: "pad-lo").dig("meta", "source", "params", "leaf_align")
    assert_equal "pad-hi", document(leaf_align: "pad-hi").dig("meta", "source", "params", "leaf_align")
    assert_equal "off", document.dig("meta", "source", "params", "leaf_align")
  end

  def test_pad_hi_inserts_a_joint_above_the_shallow_subtree
    aligned = document(leaf_align: "pad-hi")
    nodes = aligned.fetch("nodes").to_h { |node| [node["id"], node] }
    leaf = leaves(aligned).find { |node| node.dig("label", "raw") == "a" }
    subtree = nodes.fetch(leaf.fetch("parent"))
    joint = nodes.fetch(subtree.fetch("parent"))

    assert_equal "A", subtree.dig("label", "raw")
    assert_equal " ", joint.dig("label", "lines", 0, "segments", 0, "text")
    assert_nil nodes.fetch(joint.fetch("parent"))["parent"]
    assert_in_delta subtree.dig("position", "x") + subtree.dig("position", "content_width") / 2.0,
                    joint.dig("position", "x") + joint.dig("position", "content_width") / 2.0, 0.5
  end

  def test_pad_hi_matches_explicit_joints
    automatic = document(leaf_align: "pad-hi")
    explicit = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        data: "[S [<> [A a]] [B [C b] [D c]]]", format: "json"
      ).draw_json
    )

    assert_equal explicit.fetch("nodes"), automatic.fetch("nodes")
    assert_equal explicit.fetch("edges"), automatic.fetch("edges")
  end

  def test_pad_hi_centers_parents_on_visible_children
    aligned = document(leaf_align: "pad-hi")
    nodes = aligned.fetch("nodes").to_h { |node| [node["id"], node] }
    root = nodes.fetch(1)
    children = root.fetch("children").map do |id|
      node = nodes.fetch(id)
      node = nodes.fetch(node.fetch("children").first) while node.dig("label", "raw") == " "
      node
    end
    centers = children.map { |node| node.dig("position", "x") + node.dig("position", "content_width") / 2.0 }
    root_center = root.dig("position", "x") + root.dig("position", "content_width") / 2.0

    assert_in_delta (centers.min + centers.max) / 2.0, root_center, 0.5
  end

  def test_pad_hi_keeps_a_shallow_subtree_together
    data = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        data: "[S [A [X a] [Y b]] [B [C [D c] [E d]]]]", format: "json", leaf_align: "pad-hi"
      ).draw_json
    )
    nodes = data.fetch("nodes").to_h { |node| [node["id"], node] }
    a = leaves(data).find { |node| node.dig("label", "raw") == "a" }
    a_parent = nodes.fetch(a.fetch("parent"))
    subtree = nodes.fetch(a_parent.fetch("parent"))

    assert_equal "X", a_parent.dig("label", "raw")
    assert_equal "A", subtree.dig("label", "raw")
    assert_equal " ", nodes.fetch(subtree.fetch("parent")).dig("label", "lines", 0, "segments", 0, "text")
  end
end
