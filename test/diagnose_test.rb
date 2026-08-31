# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "open3"
require_relative "../lib/rsyntaxtree"
require_relative "../dev/example_options"

# diagnose returns every error of the first stage that finds any, where
# check_data stops at the first error found. These tests fix the collection
# behavior: all errors of a stage, stage boundaries that stop artifacts of
# earlier mistakes from being reported as mistakes, and the equivalence of
# the two entry points' verdicts.
class DiagnoseTest < Minitest::Test
  def diagnose(text, params = {})
    RSyntaxTree::RSGenerator.diagnose(text, params)
  end

  def codes(result)
    result["errors"].map { |e| e["code"] }
  end

  def test_a_clean_input_answers_ok_and_nothing_else
    assert_equal({ "ok" => true }, diagnose("[S [NP a] [VP b]]"))
  end

  def test_three_bad_labels_are_all_reported
    result = diagnose("[S [NP **bad] [VP @notacolor:x] [PP ^^stray]]")
    refute result["ok"]
    assert_equal %w[unclosed_markup unknown_color stray_triangle], codes(result)
  end

  def test_two_bad_options_are_both_reported
    result = diagnose("[S [NP a]]", format: "bmp", direction: "xxx")
    assert_equal %w[invalid_option invalid_option], codes(result)
    assert_equal %w[format direction], result["errors"].map { |e| e["label"] }
  end

  def test_a_cross_option_conflict_is_collected_alongside_a_bad_value
    result = diagnose("[S [NP a]]", format: "bmp", derivation: "on", direction: "ltr")
    assert_equal %w[format derivation], result["errors"].map { |e| e["label"] }
  end

  # The boundary rules, one per boundary. Each mistake on the later side is
  # real on its own — the same input with the earlier mistake fixed reports
  # it — so what the boundary suppresses is reachable, just not yet.
  def test_bad_options_stop_the_input_from_being_judged
    result = diagnose("[S [NP **bad]]", format: "bmp")
    assert_equal %w[invalid_option], codes(result)
    assert_includes result["note"], "has not been checked yet"
  end

  def test_a_bad_bracket_stops_the_labels_from_being_judged
    result = diagnose("[S [NP **bad] [VP a]")
    assert_equal %w[unbalanced_brackets], codes(result)
    assert_includes result["note"], "labels have not been checked"
  end

  def test_a_bad_label_stops_the_paths_from_being_judged
    result = diagnose("[S [NP **bad] [VP a+1]]")
    assert_equal %w[unclosed_markup], codes(result)
    assert_includes result["note"], "may reveal more"
  end

  def test_a_path_error_still_arrives_once_the_labels_read
    result = diagnose("[S [NP w+1] [VP a]]")
    assert_equal %w[path_single_end], codes(result)
  end

  # The error class the label-by-label design would have missed: a rule
  # name's validity depends on whether the node turned out to have
  # daughters, which is settled only once the tree stands.
  def test_a_rule_name_with_no_rule_behind_it_is_reported
    result = diagnose('[S\t>foo]')
    assert_equal %w[rule_name_without_derivation], codes(result)
  end

  # Under derivation the same label passes its first parse — the rule name
  # is a rule name — and only the restoration step, after the tree stands,
  # finds there is no rule to name. That step has its own recovery, and
  # only this input exercises it.
  def test_the_restoration_step_reports_under_derivation_too
    result = diagnose('[S\t>foo]', derivation: "on")
    assert_equal %w[rule_name_without_derivation], codes(result)
  end

  # The restoration step must add to the collection, not replace it: a
  # raise there would throw away every error already collected on the way.
  # Only an input with a second, unrelated mistake can tell the difference.
  def test_the_restoration_step_keeps_what_was_already_collected
    result = diagnose('[S [A\t>foo] [B **bad]]', derivation: "on")
    assert_equal %w[rule_name_without_derivation unclosed_markup], codes(result).sort
  end

  def test_a_rule_name_error_is_collected_alongside_a_label_error
    result = diagnose('[S [A\t>foo] [B **bad]]')
    assert_equal %w[rule_name_without_derivation unclosed_markup], codes(result).sort
  end

  def test_the_hyphen_option_changes_the_verdict_it_gates
    assert_equal %w[bare_hyphen], codes(diagnose("[S [NP a-b]]"))
    assert_equal({ "ok" => true }, diagnose("[S [NP a-b]]", hyphen: "literal"))
  end

  def test_the_same_mistake_twice_is_one_thing_to_fix
    result = diagnose("[S [NP **bad] [VP **bad]]")
    assert_equal %w[unclosed_markup], codes(result)
  end

  def test_the_list_is_cut_short_and_says_so
    limit = RSyntaxTree::StringParser::COLLECTED_ERRORS_LIMIT
    labels = (1..limit + 5).map { |i| "[N#{i} **bad#{i}]" }.join(" ")
    result = diagnose("[S #{labels}]")
    assert_equal limit, result["errors"].length
    assert_includes result["note"], "first #{limit}"
  end

  def test_a_list_at_the_limit_is_not_called_cut_short
    limit = RSyntaxTree::StringParser::COLLECTED_ERRORS_LIMIT
    labels = (1..limit).map { |i| "[N#{i} **bad#{i}]" }.join(" ")
    result = diagnose("[S #{labels}]")
    assert_equal limit, result["errors"].length
    refute_includes result["note"].to_s, "first #{limit} problems"
  end

  # A defect while probing the options is a verdict too, the same as one
  # while drawing: nothing in diagnose answers with a backtrace.
  def test_a_defect_during_option_probing_is_a_verdict_not_a_backtrace
    explosive = Object.new
    def explosive.to_s = raise "boom"
    result = diagnose("[S [NP a]]", format: explosive)
    assert_equal %w[internal_error], codes(result)
  end

  def test_empty_input_is_one_error
    assert_equal %w[empty_input], codes(diagnose(""))
    assert_equal %w[empty_input], codes(diagnose(nil))
  end

  # Whitespace leaves no label behind, so it is nothing to draw rather than
  # something the library failed at. It used to be reported as a defect —
  # internal_error, not retryable — which told the caller their own fixable
  # input was our fault.
  def test_whitespace_alone_is_an_empty_input
    ["   ", "\t\n ", " "].each do |blank|
      assert_equal %w[empty_input], codes(diagnose(blank)), blank.inspect
    end
  end

  # A single character is a label on its own, which the manual says draws as
  # one leaf; the tokenizer used to stop one character early and hand the
  # drawing an empty tree.
  def test_a_one_character_label_is_a_tree
    assert_equal({ "ok" => true }, diagnose("A"))
    assert_equal({ "ok" => true }, diagnose("<>"))
  end

  # The two entry points must never disagree about whether an input is
  # good: a caller switching from check_data to diagnose, or the CLI's
  # --validate against a later draw, must get the same verdict. Asked of
  # both implementations across every gallery example — under the options
  # the example actually records, read through the same ExampleOptions
  # table the drawing and its test read, so this cannot drift into judging
  # by defaults — and a battery of ways of breaking each: the first label,
  # the last label, the bracket structure.
  def test_diagnose_and_check_data_agree_on_every_example_and_its_mutations
    examples = Dir.glob(File.expand_path("../docs/_examples/*.md", __dir__))
    refute_empty examples
    examples.each do |path|
      _name, opts = ExampleOptions.load(path)
      body = opts.delete(:data)
      opts.delete(:name)
      opts[:format] = "svg"

      mutations = { "as committed" => body }
      if (last = body.rindex("["))
        mutations["a bracket removed"] = body.sub("]", "")
        mutations["the first label broken"] = body.sub("[", "[**")
        mutations["a stray triangle"] = body.sub("[", "[^^")
        mutations["the last label broken"] = body[0..last] + "**" + body[last + 1..]
      else
        # A bracketless example is a single label; break the label itself.
        mutations["markup broken"] = "**#{body}"
      end
      mutations.each do |name, data|
        verdict = begin
          RSyntaxTree::RSGenerator.check_data(data, opts)
          true
        rescue RSTError
          false
        end
        assert_equal verdict, diagnose(data, opts)["ok"],
                     "#{File.basename(path)} (#{name}): the two verdicts disagree"
      end
    end
  end
end
