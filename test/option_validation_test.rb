# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# Library-side option validation. The CLI has always rejected bad option
# values; the library used to take them silently — a misspelled scheme
# quietly became "off", an unknown direction quietly became ttb — which
# left every programmatic caller (the web UI, a future MCP server)
# unguarded. These tests fix both sides of the contract: what is rejected,
# and what every current caller sends that must keep passing.
class OptionValidationTest < Minitest::Test
  def build(opts)
    RSyntaxTree::RSGenerator.new({ data: "[S a]" }.merge(opts))
    nil
  rescue RSTError => e
    e
  end

  def test_an_unknown_direction_is_rejected_instead_of_becoming_ttb
    e = build(direction: "left-to-right")
    assert_equal :invalid_option, e.code
    refute e.retryable
    assert_includes e.hint, "ttb"
  end

  def test_a_misspelled_color_scheme_is_rejected_instead_of_becoming_off
    e = build(color: "moderm")
    assert_equal :invalid_option, e.code
    assert_includes e.hint, "modern"
  end

  def test_every_enum_rejects_a_bad_value
    {
      format: "bmp", leafstyle: "squiggle", fontstyle: "comic-sans",
      color: "blue", tidy: "dense", hyphen: "raw",
      # Right to left is not a direction. It is the mirror option, which
      # composes with either direction, and naming it here as well would make
      # two spellings for one layout.
      direction: "rtl",
      derivation: "sometimes"
    }.each do |key, value|
      e = build(key => value)
      assert_equal :invalid_option, e.code, "#{key}: #{value} should be rejected"
    end
  end

  def test_every_documented_alias_still_passes
    [
      { color: "none" }, { color: "grey" }, { color: "on" }, { color: "off" },
      { fontstyle: "noto-serif" }, { fontstyle: "noto-sans" }, { fontstyle: "noto-sans-mono" },
      { fontstyle: "mono" }, { fontstyle: "serif" }, { fontstyle: "cjk" },
      { tidy: "compact" }, { tidy: "on" }, { tidy: "symmetric" },
      { direction: "ltr" }, { direction: "ttb" },
      { hyphen: "literal" }, { leafstyle: "none" }, { leafstyle: "bar" },
      { format: "svg" }
    ].each do |opts|
      assert_nil build(opts), "#{opts} should pass"
    end
  end

  def test_the_values_the_web_ui_sends_all_pass
    [
      { tidy: "symmetric" }, { tidy: "off" }, { tidy: "low" }, { tidy: "medium" }, { tidy: "high" },
      { hspacing: "0.75" }, { vheight: "2.0" },
      { direction: "ttb" }, { direction: "ltr" },
      { fontstyle: "noto-serif" }, { fontstyle: "noto-sans" }, { fontstyle: "noto-sans-mono" },
      { fontsize: "6" }, { fontsize: "26" },
      { color: "modern" }, { color: "traditional" }, { color: "gray" }, { color: "none" },
      { hyphen: "markup" }, { hyphen: "literal" },
      { leafstyle: "auto" }, { leafstyle: "bar" }, { leafstyle: "nothing" },
      { linewidth: "0.5" }, { linewidth: "1" }, { linewidth: "1.5" }, { linewidth: "2" }, { linewidth: "2.5" }, { linewidth: "3" },
      { mirror: "on" }, { transparent: "off" }, { polyline: "on" }, { hide_default_connectors: "off" }
    ].each do |opts|
      assert_nil build(opts), "web UI value #{opts} should pass"
    end
  end

  def test_numeric_ranges_are_checked
    assert_equal :invalid_option, build(fontsize: 5).code
    assert_equal :invalid_option, build(fontsize: 27).code
    assert_equal :invalid_option, build(fontsize: "abc").code
    assert_equal :invalid_option, build(linewidth: 0).code
    assert_equal :invalid_option, build(vheight: 6.0).code
    assert_equal :invalid_option, build(hspacing: 0.1).code
    assert_nil build(fontsize: 6)
    assert_nil build(fontsize: 26)
  end

  def test_validation_runs_through_check_data
    e = begin
      RSyntaxTree::RSGenerator.check_data("[S a]", direction: "upside-down")
      nil
    rescue RSTError => err
      err
    end
    assert_equal :invalid_option, e.code
  end

  # An HTML form posts a field for every control it carries, and a control with
  # nothing selected posts the empty string. So a form that has outlived one of
  # its own controls keeps sending that field, empty, alongside everything else
  # — which is how the web UI came to send `format=` on every download and get
  # 500 back for every input, the reason nowhere a user could see it. An option
  # given as an empty string is an option not given, and the default stands.
  def test_an_empty_value_is_no_value_rather_than_a_bad_one
    OPTION_VALUES.each_key do |key|
      assert_nil build(key => ""), "#{key}: an empty value should be read as unset"
      assert_nil build(key => nil), "#{key}: nil should be read as unset"
    end
    NUMERIC_RANGES.each_key do |key|
      assert_nil build(key => ""), "#{key}: an empty value should be read as unset"
    end
  end

  # And the default really is what stands — an empty value must not reach the
  # drawing as a zero or a blank.
  def test_an_empty_value_leaves_the_default_in_place
    plain = RSyntaxTree::RSGenerator.new(data: "[S [NP a] [VP b]]").draw_svg
    emptied = RSyntaxTree::RSGenerator.new(data: "[S [NP a] [VP b]]", format: "", fontsize: "",
                                           color: "", direction: "", vheight: "").draw_svg
    assert_equal plain, emptied
  end

  def test_unknown_keys_still_pass_because_callers_send_their_own
    assert_nil build(my_own_field: "whatever", data_extra: 1)
  end

  def test_booleans_stay_lenient
    assert_nil build(mirror: "yes")
    assert_nil build(mirror: "no")
    assert_nil build(transparent: "0")
  end

  # The CLI used to carry its own copy of every allowed value, so the library
  # and the command line could disagree about what was acceptable: `color:
  # none` in a config file worked through the library and was refused by the
  # CLI. Both now read the same list.
  def test_the_cli_accepts_every_value_the_library_does
    bin = File.expand_path("../bin/rsyntaxtree", __dir__)
    source = File.read(bin)
    %i[leafstyle fontstyle color tidy direction hyphen].each do |option|
      assert_match(/OPTION_VALUES\[:#{option}\]/, source,
                   "the CLI should take #{option} from the library, not a copy")
    end
  end
end
