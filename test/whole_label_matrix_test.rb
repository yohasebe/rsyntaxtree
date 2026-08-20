# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# A label that is one whole matrix: [#(HEAD\tnoun#)]. Until the grammar
# change that introduced it, the enclosure rule ate the '#' of '#(' before
# the matrix rule could see it, so a matrix could never BE a label, only
# live inside one.
#
# This file first records how the seven boundary inputs behaved before the
# change (verified against the pre-change code), then fixes the contract
# after the change: what used to succeed must succeed unchanged, and the
# only failures that flipped are the ones the feature means to flip.
class WholeLabelMatrixTest < Minitest::Test
  def check(text)
    RSyntaxTree::RSGenerator.check_data(text, {})
    :success
  rescue RSTError
    :failure
  end

  # Behavior recorded before the grammar change:
  #   [#(foo) bar]  success  (enclosure '#' + plain text)
  #   [#(foo)]      success  (enclosure '#' + plain text)
  #   [#(a]         success  (enclosure '#' + plain text)
  #   [#(a#)]       failure
  #   [#(HEAD\tnoun#)] failure
  #   [#(a#) b]     failure
  #   [#(a\nb#)]    failure

  # The change must not alter the interpretation of anything that parsed
  # before: these three succeeded and must still succeed, by falling
  # through to the enclosure reading when the whole-matrix reading fails.
  def test_inputs_that_succeeded_before_still_succeed
    assert_equal :success, check("[#(foo) bar]")
    assert_equal :success, check("[#(foo)]")
    assert_equal :success, check("[#(a]")
  end

  # A matrix followed by more text in the SAME label (no raw space to
  # split it off) is still not parseable: the whole-matrix reading requires
  # the matrix to cover the label, and the enclosure reading cannot
  # consume the '#'. This failed before and must still fail.
  def test_a_matrix_that_does_not_cover_the_whole_label_still_fails
    assert_equal :failure, check("[#(a#)x]")
  end

  # The feature itself: inputs that failed before and now parse, because
  # the label IS one matrix. A raw space still splits a label from its
  # children, so '[#(a#) b]' is now a matrix node with child 'b'.
  def test_a_whole_label_matrix_now_parses
    assert_equal :success, check("[#(HEAD\\tnoun#)]")
    assert_equal :success, check("[#(a#)]")
    assert_equal :success, check("[#(a\\nb#)]")
    assert_equal :success, check("[#(a#) b]")
  end

  def test_a_whole_label_matrix_nests
    assert_equal :success, check("[#(HEAD\\tnoun\\\n  SUBJ\\t#(PRED\\t'walks'#)#)]")
  end

  def test_a_whole_label_matrix_draws_an_svg
    svg = RSyntaxTree::RSGenerator.new(data: "[#(HEAD\\tnoun#)]", format: "svg").draw_svg
    assert_includes svg, "<svg"
    assert_includes svg, "HEAD"
    assert_includes svg, "noun"
  end

  def test_a_whole_label_matrix_with_a_path
    assert_equal :success, check("[#(HEAD\\tnoun#)+>1 [X+1 t]]")
  end

  def test_a_whole_label_matrix_under_hyphen_literal
    RSyntaxTree::RSGenerator.check_data("[#(FORM\\tsprite-f#)]", hyphen: "literal")
  rescue RSTError => e
    flunk("hyphen: literal whole-label matrix should parse, got #{e.code}")
  end
end
