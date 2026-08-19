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

  # ===================
  # Library-level conversion
  # ===================

  # Conversion lives in the library, not only in the CLI: every caller —
  # the web UI, an MCP server, any direct user of RSGenerator — gets the
  # documented automatic conversion.
  def test_generator_converts_penn_input
    require_relative "../lib/rsyntaxtree"

    svg = RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(data: "(S (NP the dog) (VP runs))")).draw_svg

    assert_includes svg, "the"
    assert_includes svg, "dog"
    assert_includes svg, "runs"
    texts = svg.scan(/<tspan[^>]*>([^<]*)</).flatten
    assert_includes texts, "NP", "NP should be a node label, not part of a single leaf"
  end

  def test_bracket_input_passes_through_unchanged
    # Conversion runs on every input now, so what it leaves alone matters as
    # much as what it rewrites: a matrix carries parentheses of its own in
    # `#( ... #)`, and collapsing whitespace would flatten its rows.
    matrix = '[#PRED\t(x)\nOBJ\t#(PRED\tY#)]'
    [
      "[S [NP a] [VP b]]",
      matrix,
      "([ this starts with a paren but is not Penn ])"
    ].each do |data|
      assert_equal data, RSyntaxTree::FormatConverter.to_bracket(data)
    end
  end

  def test_a_lone_parenthesised_label_is_read_as_penn
    # Nothing distinguishes `(hello)` from a one-node Penn tree, so it
    # converts. Pinned because the parentheses disappear from the figure.
    assert_equal "[hello]", RSyntaxTree::FormatConverter.to_bracket("(hello)")
  end

  def test_check_data_accepts_penn_input
    require_relative "../lib/rsyntaxtree"

    assert RSyntaxTree::RSGenerator.check_data("(S (NP the dog) (VP runs))")
  end
end
