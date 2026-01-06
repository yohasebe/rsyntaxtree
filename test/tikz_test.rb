# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree"

class TikZTest < Minitest::Test
  def setup
    @simple_opts = {
      data: "[S [NP hello] [VP world]]",
      fontstyle: "sans"
    }
  end

  def test_draw_tikz_returns_string
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert_kind_of String, tikz
    refute_empty tikz
  end

  def test_tikz_contains_forest_environment
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("\\begin{forest}"), "Should contain forest begin"
    assert tikz.include?("\\end{forest}"), "Should contain forest end"
  end

  def test_tikz_contains_tree_structure
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("[S"), "Should contain root node S"
    assert tikz.include?("[NP"), "Should contain NP node"
    assert tikz.include?("[VP"), "Should contain VP node"
    assert tikz.include?("hello"), "Should contain terminal hello"
    assert tikz.include?("world"), "Should contain terminal world"
  end

  def test_tikz_with_nested_tree
    opts = {
      data: "[S [NP [Det the] [N dog]] [VP [V runs]]]",
      fontstyle: "sans"
    }
    rsg = RSyntaxTree::RSGenerator.new(opts)
    tikz = rsg.draw_tikz

    assert tikz.include?("[Det"), "Should contain Det node"
    assert tikz.include?("[N"), "Should contain N node"
    assert tikz.include?("[V"), "Should contain V node"
    assert tikz.include?("the"), "Should contain terminal 'the'"
    assert tikz.include?("dog"), "Should contain terminal 'dog'"
  end

  def test_tikz_escapes_special_chars
    # Use % and $ which are LaTeX special but not RSyntaxTree special
    # (underscore _ is RSyntaxTree subscript markup, so we avoid it)
    opts = {
      data: "[S [NP 50%] [VP $100]]",
      fontstyle: "sans"
    }
    rsg = RSyntaxTree::RSGenerator.new(opts)
    tikz = rsg.draw_tikz

    # LaTeX special chars should be escaped
    assert tikz.include?("\\%"), "Should escape percent sign"
    assert tikz.include?("\\$"), "Should escape dollar sign"
  end

  def test_tikz_generates_standalone_option
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz(standalone: true)

    assert tikz.include?("\\documentclass"), "Standalone should have documentclass"
    assert tikz.include?("\\usepackage{forest}"), "Should include forest package"
    assert tikz.include?("\\begin{document}"), "Should have document begin"
    assert tikz.include?("\\end{document}"), "Should have document end"
  end

  def test_tikz_non_standalone_no_preamble
    rsg = RSyntaxTree::RSGenerator.new(@simple_opts)
    tikz = rsg.draw_tikz(standalone: false)

    refute tikz.include?("\\documentclass"), "Non-standalone should not have documentclass"
    refute tikz.include?("\\begin{document}"), "Non-standalone should not have document"
  end
end
