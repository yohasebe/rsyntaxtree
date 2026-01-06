# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree/format_converter"

class FormatConverterTest < Minitest::Test
  # ===================
  # Penn TreeBank format conversion
  # ===================

  def test_simple_penn_to_bracket
    penn = "(S (NP hello) (VP world))"
    expected = "[S [NP hello] [VP world]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_nested_penn_to_bracket
    penn = "(S (NP (Det the) (N dog)) (VP (V runs)))"
    expected = "[S [NP [Det the] [N dog]] [VP [V runs]]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_with_spaces
    penn = "( S ( NP hello ) ( VP world ) )"
    expected = "[S [NP hello] [VP world]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_multiline
    penn = <<~PENN
      (S
        (NP (Det the) (N cat))
        (VP (V sat)))
    PENN
    expected = "[S [NP [Det the] [N cat]] [VP [V sat]]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_with_complex_labels
    penn = "(S (NP-SBJ hello) (VP world))"
    expected = "[S [NP-SBJ hello] [VP world]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_empty_node
    penn = "(S (NP) (VP test))"
    expected = "[S [NP] [VP test]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  # ===================
  # Format detection
  # ===================

  def test_detect_penn_format
    penn = "(S (NP hello) (VP world))"
    assert_equal :penn, RSyntaxTree::FormatConverter.detect_format(penn)
  end

  def test_detect_bracket_format
    bracket = "[S [NP hello] [VP world]]"
    assert_equal :bracket, RSyntaxTree::FormatConverter.detect_format(bracket)
  end

  def test_detect_bracket_with_markup
    bracket = "[S [NP **hello**] [VP world]]"
    assert_equal :bracket, RSyntaxTree::FormatConverter.detect_format(bracket)
  end

  # ===================
  # Auto-conversion
  # ===================

  def test_auto_convert_penn
    penn = "(S (NP hello) (VP world))"
    expected = "[S [NP hello] [VP world]]"
    assert_equal expected, RSyntaxTree::FormatConverter.to_bracket(penn)
  end

  def test_auto_convert_bracket_unchanged
    bracket = "[S [NP hello] [VP world]]"
    assert_equal bracket, RSyntaxTree::FormatConverter.to_bracket(bracket)
  end

  # ===================
  # Edge cases
  # ===================

  def test_penn_single_node
    penn = "(NP hello)"
    expected = "[NP hello]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_leaf_only
    penn = "(N dog)"
    expected = "[N dog]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_with_numbers
    penn = "(NP (CD 123) (NN items))"
    expected = "[NP [CD 123] [NN items]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  # ===================
  # Escaped characters
  # ===================

  def test_penn_with_escaped_parentheses
    penn = '(S (NP hello\(world\)) (VP test))'
    expected = "[S [NP hello(world)] [VP test]]"
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_with_escaped_brackets
    penn = '(S (NP \[hello\]) (VP test))'
    expected = '[S [NP \[hello\]] [VP test]]'
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end

  def test_penn_with_mixed_escaped_chars
    penn = '(S (NP \(a\) and \[b\]) (VP test))'
    expected = '[S [NP (a) and \[b\]] [VP test]]'
    assert_equal expected, RSyntaxTree::FormatConverter.penn_to_bracket(penn)
  end
end
