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

  def test_an_unnamed_cause_does_not_mean_an_unfixable_input
    # No single repair fits, so no cause is named. That is not a reason to
    # stop: what lands here is usually two mistakes at once, each of them
    # one that would have been named on its own.
    e = failure("[X 1+1=2]")
    assert_equal :invalid_markup, e.code
    assert e.retryable
  end

  def test_compound_mistakes_fall_to_invalid_markup_and_are_still_fixable
    # A bare hyphen and ASCII angle brackets together are beyond any single
    # repair, so the catch-all is the honest answer rather than one of the
    # two causes — but correcting both does make the label parse.
    e = failure("[X\nHEAD-DTR\t〈ok〉\nSPR\t<NP>]")
    assert_equal :invalid_markup, e.code
    assert e.retryable
    assert RSyntaxTree::RSGenerator.check_data("[X\nHEAD\\-DTR\t〈ok〉\nSPR\t〈NP〉]")
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

  # Checks that only happen once the tree is laid out have to be part of
  # validation too, or "this input is fine" is a promise it cannot keep.
  def test_path_with_one_end_is_rejected_by_validation_as_well_as_drawing
    e = failure("[A [B x+-2] [C y]]")
    assert_equal :path_single_end, e.code
    assert e.retryable

    drawn = assert_raises(RSTError) do
      RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: "[A [B x+-2] [C y]]")).draw_svg
    end
    assert_equal e.code, drawn.code
  end

  # Text pasted in front of a tree makes a second root. Symmetrization used
  # to look for that root's parent and find nothing.
  def test_text_in_front_of_a_tree_draws_in_every_layout
    %w[off symmetric low medium high].each do |tidy|
      svg = RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: "Example 3: [S [NP the cat] [VP sat]]", tidy: tidy)
      ).draw_svg
      assert_includes svg, "<svg", tidy
    end
  end

  # Whatever goes wrong, callers are promised a verdict they can read.
  def test_a_failure_inside_the_drawing_code_still_comes_back_as_a_verdict
    assert_equal :internal_error,
                 RSTError.new("Error: input could not be processed (NoMethodError)",
                              code: :internal_error).code
  end

  # The angle-bracket trap is the first one the notation reference names and
  # the most common one measured, so it must not fall through to the
  # catch-all: a caller needs to be told to write ⟨ ⟩, and told it in the
  # narrow pair the reference names rather than the East Asian one, which
  # draws a full em wide. The hint is where a model reads it, so the wrong
  # character here teaches itself.
  def test_ascii_angle_brackets_are_classified
    ['[#SPR\t<NP>]', "[#PRED\t'hand<SUBJ,OBJ>']"].each do |data|
      e = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data(data) }
      assert_equal :angle_brackets, e.code, data
      assert e.retryable, data
      assert_includes e.hint, "⟨"
      refute_includes e.hint, "〈", "the hint teaches the East Asian bracket"
    end
  end

  # Both pairs still parse: documents written before the reference settled on
  # one of them are not broken by settling on it.
  def test_both_angle_bracket_pairs_are_accepted
    assert RSyntaxTree::RSGenerator.check_data('[#SPR\t〈<>NP<>〉]')
    assert RSyntaxTree::RSGenerator.check_data('[#SPR\t⟨<>NP<>⟩]')
  end

  # A hint repairs what is in front of it. A caller that was guessing at the
  # notation needs to be told where the notation is.
  def test_the_diagnosis_says_where_the_notation_is
    e = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data('[#SPR\t<NP>]') }
    assert_includes e.to_h["reference"], "--notation"
    assert_includes e.to_h["reference"], "llms-full.txt"
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
