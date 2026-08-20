# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# Color specifications: a malformed one must be named as a color mistake
# (not as the enclosure mistake its bare '#' used to suggest), and a color
# name must be one librsvg can actually paint, because validation promises
# that what passes also draws.
class ColorTest < Minitest::Test
  def check(text)
    RSyntaxTree::RSGenerator.check_data(text, {})
    nil
  rescue RSTError => e
    e
  end

  def test_two_digit_hex_is_named_a_color_mistake
    e = check("[@#ff:X]")
    assert_equal :invalid_color, e.code
    assert e.retryable
    assert_includes e.hint, "@#rgb:"
  end

  def test_non_hex_characters_are_named_a_color_mistake
    e = check("[@#gg:X]")
    assert_equal :invalid_color, e.code
  end

  def test_eight_digit_hex_is_named_a_color_mistake
    e = check("[@#aabbccdd:X]")
    assert_equal :invalid_color, e.code
  end

  def test_a_valid_hex_color_still_passes
    assert_nil check("[@#3af:X]")
    assert_nil check("[@#E63946:X]")
  end

  def test_a_valid_color_spec_with_other_markup_trouble_is_not_blamed
    e = check("[@blue:V*bar]")
    refute_equal :invalid_color, e.code
  end

  def test_an_unknown_color_name_is_rejected
    e = check("[@notacolor:X]")
    assert_equal :unknown_color, e.code
    assert e.retryable
    assert_includes e.message, "notacolor"
  end

  def test_known_color_names_pass
    assert_nil check("[@blue:X]")
    assert_nil check("[@rebeccapurple:X]")
    assert_nil check("[@lightblue:X]")
    assert_nil check("[@transparent:X]")
  end

  def test_color_names_are_case_insensitive
    assert_nil check("[@Grey:X]")
    assert_nil check("[@LightBlue:X]")
  end

  def test_region_shade_color_is_validated_too
    e = check("[%@notacolor:X [Y a]]")
    assert_equal :unknown_color, e.code
    assert_nil check("[%@yellow:X [Y a]]")
  end

  def test_the_name_list_is_complete_and_normalized
    assert_equal 149, RSyntaxTree::COLOR_NAMES.size
    assert_equal RSyntaxTree::COLOR_NAMES.uniq, RSyntaxTree::COLOR_NAMES
    assert RSyntaxTree::COLOR_NAMES.all? { |n| n == n.downcase }
  end

  # A region shade carries the same colour syntax behind a `%`, and the
  # diagnosis has to see past that prefix or it blames the enclosure.
  def test_a_broken_colour_on_a_region_shade_is_named_as_a_colour
    error = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data("[%@#ff:VP [NP a]]") }
    assert_equal :invalid_color, error.code

    error = assert_raises(RSTError) { RSyntaxTree::RSGenerator.check_data("[%@notacolor:VP [NP a]]") }
    assert_equal :unknown_color, error.code

    assert RSyntaxTree::RSGenerator.check_data("[%@lightblue:VP [NP a]]")
    assert RSyntaxTree::RSGenerator.check_data("[%VP [NP a]]")
  end
end
