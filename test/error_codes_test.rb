# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/rsyntaxtree"

# RSTError::CODES is the published set of error codes, and this is what keeps
# it from drifting away from the library that raises them. The list is written
# out by hand because it is a contract; the check is derived, by reading the
# raises and the repair table, so an added code fails here until it is
# declared and a removed one cannot linger.
class ErrorCodesTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)

  # The codes the library can actually produce: every `code:` given to
  # RSTError.new, plus the repair table's, which reach the constructor
  # splatted rather than written at the raise.
  def raised_codes
    codes = Set.new(RSyntaxTree::Element::MARKUP_REPAIRS.map { |code, _, _| code })
    Dir.glob(File.join(LIB, "**", "*.rb")).each do |path|
      src = File.read(path)
      src.to_enum(:scan, /RSTError\.new\(/).each do
        codes.merge(balanced_call(src, Regexp.last_match.begin(0)).scan(/code:\s*:([a-z_]+)/).flatten.map(&:to_sym))
      end
    end
    # markup_failure_details falls back to this when no single repair fits;
    # it is set in that method rather than at a raise.
    codes << :invalid_markup
    codes
  end

  # The RSTError.new(...) expression beginning at `start`, to its closing
  # parenthesis — the arguments span several lines at most raise sites.
  def balanced_call(src, start)
    depth = 0
    i = src.index("(", start)
    j = i
    while j < src.length
      depth += 1 if src[j] == "("
      depth -= 1 if src[j] == ")"
      break if depth.zero?
      j += 1
    end
    src[start..j]
  end

  def test_codes_lists_exactly_what_the_library_raises
    assert_equal raised_codes.to_a.sort, RSTError::CODES.sort,
                 "RSTError::CODES and the codes the library raises have diverged"
  end

  def test_codes_is_a_frozen_list_of_symbols
    assert RSTError::CODES.frozen?
    assert(RSTError::CODES.all?(Symbol))
    assert_equal RSTError::CODES.uniq, RSTError::CODES
    assert_equal RSTError::CODES.sort, RSTError::CODES, "keep the list sorted so a diff reads"
  end

  # The diagnosis is what consumers read, so a code appearing there and not
  # in the list would be exactly the drift this guards against.
  def test_every_code_a_diagnosis_reports_is_declared
    inputs = [["", {}], ["   ", {}], ["[S [NP a]]", { format: "bmp" }],
              ["[S [NP a] [VP b]", {}], ["[S []]", {}],
              ["[S [NP **bad] [VP @notacolor:x] [PP ^^stray]]", {}],
              ["[S [NP a-b]]", {}], ["[S [NP <NP>]]", {}],
              ["[S [NP #(A\\tB]]", {}], ["[S [NP a+]]", {}],
              ["[S [NP w+1] [VP a]]", {}], ['[S\t>foo]', {}],
              ["[S [NP @#gg:a]]", {}]]
    seen = inputs.flat_map do |data, opts|
      (RSyntaxTree::RSGenerator.diagnose(data, opts)["errors"] || []).map { |e| e["code"].to_sym }
    end
    refute_empty seen
    (seen.uniq - RSTError::CODES).each do |code|
      flunk "diagnose reported #{code}, which RSTError::CODES does not declare"
    end
  end
end
