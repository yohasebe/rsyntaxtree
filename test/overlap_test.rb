# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'

class OverlapTest < Minitest::Test
  # Check that no two nodes at the same tree level overlap horizontally (TTB)
  # or vertically (LTR). This catches cases where cousins (not just siblings)
  # overlap due to long labels extending beyond their subtree allocation.
  def assert_no_level_overlap(lsif_json, direction = "ttb")
    data = JSON.parse(lsif_json)
    nodes = data["nodes"]

    # Group nodes by level
    levels = {}
    nodes.each do |n|
      level = n["level"]
      next unless level
      levels[level] ||= []
      levels[level] << n
    end

    levels.each do |level, level_nodes|
      next if level_nodes.size < 2

      if direction == "ltr"
        # LTR: check vertical overlap
        sorted = level_nodes.sort_by { |n| n["position"]["y"] }
        sorted.each_cons(2) do |a, b|
          a_bottom = a["position"]["y"] + a["position"]["content_height"]
          b_top = b["position"]["y"]
          gap = b_top - a_bottom
          assert gap >= 0,
            "Level #{level} overlap: '#{a["label"]["raw"]}' bottom (#{a_bottom.round}) " \
            "> '#{b["label"]["raw"]}' top (#{b_top.round}), gap=#{gap.round}"
        end
      else
        # TTB: check horizontal overlap
        sorted = level_nodes.sort_by { |n| n["position"]["x"] }
        sorted.each_cons(2) do |a, b|
          a_right = a["position"]["x"] + a["position"]["content_width"]
          b_left = b["position"]["x"]
          gap = b_left - a_right
          assert gap >= 0,
            "Level #{level} overlap: '#{a["label"]["raw"]}' right (#{a_right.round}) " \
            "> '#{b["label"]["raw"]}' left (#{b_left.round}), gap=#{gap.round}"
        end
      end
    end
  end

  # --- TTB overlap tests ---

  def test_user_reported_overlap
    # Reproduces the overlap from user screenshot: +Agr3MSG vs AspPERFECT
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[T' [TPAST [\\+Agr3MSG [a]]] [AspP [AspPERFECT [u,i]]] [VoiceP [VoicePASSIVE [pasive]] [vP [vPASSIVE] [VP [√KTB] [*t*_i_]]]]]"
    opts[:fontstyle] = "serif"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    assert_no_level_overlap(rsg.draw_lsif)
  end

  def test_long_cousin_labels_no_overlap
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[Root [A [VeryLongLabelOne x]] [B [VeryLongLabelTwo y]]]"
    opts[:fontstyle] = "serif"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    assert_no_level_overlap(rsg.draw_lsif)
  end

  def test_wide_leaf_under_narrow_parent
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [A [LongChildLabel]] [B [AnotherLongChild]]]"
    opts[:fontstyle] = "serif"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    assert_no_level_overlap(rsg.draw_lsif)
  end

  def test_three_siblings_with_long_children
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[S [X [LongNameAlpha a]] [Y [LongNameBeta b]] [Z [LongNameGamma c]]]"
    opts[:fontstyle] = "serif"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    assert_no_level_overlap(rsg.draw_lsif)
  end

  def test_different_font_styles
    ["sans", "serif", "mono"].each do |style|
      opts = DEFAULT_OPTS.dup
      opts[:data] = "[Root [A [VeryLongLabel x]] [B [AnotherLongOne y]]]"
      opts[:fontstyle] = style
      rsg = RSyntaxTree::RSGenerator.new(opts)
      assert_no_level_overlap(rsg.draw_lsif)
    end
  end

  def test_different_font_sizes
    [10, 16, 24].each do |size|
      opts = DEFAULT_OPTS.dup
      opts[:data] = "[Root [A [LongLabelHere x]] [B [AnotherLongLabel y]]]"
      opts[:fontstyle] = "serif"
      opts[:fontsize] = size
      rsg = RSyntaxTree::RSGenerator.new(opts)
      assert_no_level_overlap(rsg.draw_lsif)
    end
  end

  # --- LTR overlap tests ---

  def test_ltr_long_labels_no_overlap
    opts = DEFAULT_OPTS.dup
    opts[:data] = "[Root [A [VeryLongLabelOne x]] [B [VeryLongLabelTwo y]]]"
    opts[:fontstyle] = "serif"
    opts[:direction] = "ltr"
    rsg = RSyntaxTree::RSGenerator.new(opts)
    assert_no_level_overlap(rsg.draw_lsif, "ltr")
  end
end
