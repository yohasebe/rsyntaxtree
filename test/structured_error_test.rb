# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "json"

require_relative "../lib/rsyntaxtree"

# Structured errors: the human-readable message must stay exactly as it was
# (the CLI and the web UI display it), while code, position, hint and
# retryable ride alongside for machine callers.
class StructuredErrorTest < Minitest::Test
  def failure(data, params = {})
    RSyntaxTree::RSGenerator.check_data(data, params)
    flunk "expected an RSTError for #{data.inspect}"
  rescue RSTError => e
    e
  end

  def test_bare_hyphen_is_classified_with_position
    e = failure("[X V-bar]")
    assert_equal :bare_hyphen, e.code
    assert_equal "V-bar", e.label
    assert_equal 1, e.position
    assert_includes e.hint, "\\-"
    assert e.retryable
  end

  def test_hyphen_inside_a_word_reports_the_hyphen_position
    e = failure("[X HEAD-DTR]")
    assert_equal :bare_hyphen, e.code
    assert_equal 4, e.position
  end

  def test_unclosed_italic_is_classified
    e = failure("[X *unclosed]")
    assert_equal :unclosed_markup, e.code
    assert_equal 9, e.position
    assert_includes e.hint, "*"
    assert e.retryable
  end

  def test_unclosed_box_is_classified
    e = failure("[X |box]")
    assert_equal :unclosed_markup, e.code
    assert_equal 4, e.position
    assert_includes e.hint, "|"
  end

  def test_unclosed_nested_matrix_is_classified
    e = failure('[#PRED\t#(HEAD\tx)]')
    assert_equal :unclosed_matrix, e.code
    assert_includes e.hint, "#)"
    assert e.retryable
  end

  def test_a_raw_space_splitting_a_label_is_named
    e = failure("[S\\n*a b*]")
    assert_equal :label_split, e.code
    assert_includes e.hint, "<>"
    assert e.retryable
  end

  def test_a_raw_space_inside_a_nested_value_is_named
    e = failure('[#PRED\tX\nOBJ\t#(PRED\t*a b*#)]')
    assert_equal :label_split, e.code
    assert_includes e.hint, "<>"
  end

  def test_unbalanced_brackets_are_classified
    e = failure("[S [NP a]]]")
    assert_equal :unbalanced_brackets, e.code
    assert e.retryable
  end

  def test_empty_input_is_classified_and_not_retryable
    e = failure("")
    assert_equal :empty_input, e.code
    refute e.retryable
  end

  def test_message_string_is_unchanged
    e = failure("[X V-bar]")
    assert_equal "Error: input text contains an invalid string\n > V-bar", e.message
  end

  def test_to_h_is_json_ready
    e = failure("[X V-bar]")
    h = e.to_h
    assert_equal false, h["ok"]
    error = h["errors"].first
    assert_equal "bare_hyphen", error["code"]
    assert_equal "V-bar", error["label"]
    assert_equal 1, error["position"]
    assert error["retryable"]
    assert_kind_of String, JSON.generate(h)
  end

  def test_hyphen_literal_option_is_respected
    assert RSyntaxTree::RSGenerator.check_data("[X V-bar]", hyphen: "literal")
  end

  def test_path_with_one_end_is_classified
    e = begin
      RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: "[A [B x+-2] [C y]]")).draw_svg
      flunk "expected an RSTError"
    rescue RSTError => err
      err
    end
    assert_equal :path_single_end, e.code
    assert e.retryable
  end

  # The angle-bracket trap is the first one the notation reference names and
  # the most common one measured, so it must not fall through to the
  # catch-all: a caller needs to be told to write 〈 〉.
  def test_ascii_angle_brackets_are_classified
    ['[#SPR\t<NP>]', "[#PRED\t'hand<SUBJ,OBJ>']"].each do |data|
      e = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data(data) }
      assert_equal :angle_brackets, e.code, data
      assert e.retryable, data
      assert_includes e.hint, "〈"
    end
  end

  # One malformed input per construct the notation documents. A construct
  # added to the grammar without a repair to go with it lands in the
  # catch-all, and this is what says so — the diagnosis is a separate list
  # from the grammar, so nothing but a test keeps the two together.
  def test_every_construct_can_name_its_own_failure
    {
      "triangle" => "[S ^^text]",
      "enclosure" => "[S ###]",
      "path" => "[S x+]",
      "whitespace block" => "[S a<b]",
      "subscript" => "[S x_]",
      "italic" => "[S *x]",
      "box" => "[S |x]",
      "circle" => "[S {x]",
      "overline" => "[S =x]",
      "strikethrough" => "[S ~x]",
      "nested matrix" => '[#A\tB\nC\t#(D\tE]',
      "angle brackets" => '[#SPR\t<NP>]',
      "hyphen" => "[S V-bar]"
    }.each do |construct, data|
      e = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data(data) }
      refute_equal :invalid_markup, e.code,
                   "#{construct} (#{data}) has no diagnosis of its own"
    end
  end

  # The point of the classification is that a caller can act on it. Every
  # way of getting the notation wrong must come back named, with a fix, and
  # marked worth another try.
  def test_every_realistic_mistake_is_named_and_actionable
    [
      "[S V-bar]",                              # hyphen opens an underline
      "[S *unclosed]",                          # decoration never closed
      "[S |box]",                               # box never closed
      '[#SPR\t<NP>]',                           # ASCII angle brackets
      '[S\n*a b*]',                             # space splits the label
      '[#PRED\tX\nOBJ\t#(PRED\ta toy#)]',       # space breaks a nested matrix
      "[S [NP a",                               # brackets do not match
      "[S []]"                                  # nothing inside the brackets
    ].each do |data|
      e = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data(data) }
      refute_equal :invalid, e.code, data
      assert e.retryable, "#{data} was reported as not worth retrying"
      assert e.hint, "#{data} came back without a fix"
    end
  end

  # retryable: false means no rewriting of the input can help. An unnamed
  # markup failure is still a mistake in the input, so it stays retryable —
  # telling a caller to give up on a fixable error is the worse mistake.
  def test_an_unnamed_markup_failure_is_still_retryable
    e = RSTError.new("Error: input text contains an invalid string", code: :invalid_markup, retryable: true)
    assert e.retryable
    assert_equal false, RSTError.new("Error: input text is empty", code: :empty_input).retryable
  end
end
