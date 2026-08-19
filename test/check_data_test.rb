# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# check_data used to stop at bracket balance, so label markup that rendering
# rejects passed validation: a caller could be told "OK" and still fail at
# draw time. These cases are taken from that failure mode, and pin the two
# gates: markup must parse, and brackets must still balance.
class CheckDataTest < Minitest::Test
  def test_unpaired_underline_in_a_label_is_rejected
    # A bare hyphen in a word opens an underline that never closes.
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data('[#*f-structure*\nPRED\tX]')
    end
  end

  def test_a_raw_space_inside_a_nested_value_is_rejected
    # The space in 'a b' splits the value and leaves the matrix unclosed.
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data('[#PRED\tX\nOBJ\t#(PRED\t*a b*#)]')
    end
  end

  def test_an_unclosed_bracket_is_rejected
    # Drawing closes it implicitly and produces a tree, which is exactly why
    # validation has to speak up: the writer never asked for that tree.
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data("[S [NP a")
    end
  end

  def test_a_stray_closing_bracket_is_rejected
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data("[S [NP a]]]")
    end
  end

  def test_text_without_brackets_passes
    # A label on its own draws as a single leaf, so it validates.
    assert RSyntaxTree::RSGenerator.check_data("hello")
  end

  def test_options_are_honoured
    # With hyphen: "literal" the hyphen is a character, not an underline,
    # so the same label validates under one option set and not the other.
    data = '[#PRED\t*rely-rel*]'
    assert RSyntaxTree::RSGenerator.check_data(data, hyphen: "literal")
    assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data(data) }
  end

  def test_empty_brackets_are_rejected
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data("[S []]")
    end
  end

  def test_empty_input_is_rejected
    assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.check_data("")
    end
  end

  def test_valid_tree_passes
    assert RSyntaxTree::RSGenerator.check_data("[S [NP a] [VP b]]")
  end

  def test_valid_matrix_passes
    assert RSyntaxTree::RSGenerator.check_data('[#HEAD\tnoun\nSPR\t〈<>〉\nCOMPS\t〈<>NP<>〉]')
  end
end
