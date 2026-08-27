# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# The notation is documented in three places a person reads — the one-page
# reference the gem ships (`--notation`), and the two manuals — and each is
# written by hand, in its own language, for its own reader. What keeps them
# honest is not a shared source but this file: the set of features is taken
# from the grammar itself, every feature has a sample here, the sample is run
# through the parser to prove it shows what it claims to, and each document is
# required to carry it. A feature added to the grammar with no row here fails;
# a document that drops a sample fails; a sample that stops meaning what it
# says fails.
#
# The traps are held to the same standard, more strictly: a trap is an input
# the tool accepts and draws as something other than what was plainly meant,
# so every trap sample must still be accepted (one the tool rejects is not a
# trap — the error message covers it) and must still produce the surprise the
# document warns about. This is what was missing when the parenthesis warning
# outlived the Penn Treebank conversion that made it false.
class NotationIndexTest < Minitest::Test
  include RSyntaxTree

  GRAMMAR = File.read(File.expand_path("../lib/rsyntaxtree/markup_parser.rb", __dir__))
  DOCUMENTS = {
    "notation_core.md" => File.read(File.expand_path("../lib/rsyntaxtree/notation_core.md", __dir__)),
    "documentation.md" => File.read(File.expand_path("../docs/documentation.md", __dir__)),
    "documentation_ja.md" => File.read(File.expand_path("../docs/documentation_ja.md", __dir__))
  }.freeze

  # One sample per grammar feature: the notation as a reader would type it, and
  # the names the evaluated parse must mention for the sample to be showing
  # that feature. The evaluator normalises some grammar rules into flags
  # (empty_box comes out as :box, horizontal_bar as :bar, arrow_both as its two
  # heads), so the expectation is written in the evaluator's terms.
  SAMPLES = {
    # rule(:decoration)
    "italic" => { sample: "*x*", shows: [:italic] },
    "bold" => { sample: "**x**", shows: [:bold] },
    "bolditalic" => { sample: "***x***", shows: [:bolditalic] },
    "subscript" => { sample: "x_i_", shows: [:subscript] },
    "superscript" => { sample: "x__2__", shows: [:superscript] },
    "small" => { sample: "H___EAD___", shows: [:small] },
    "overline" => { sample: "=x=", shows: [:overline] },
    "underline" => { sample: "-x-", shows: [:underline] },
    "linethrough" => { sample: "~x~", shows: [:linethrough] },
    # rule(:shape)
    "box" => { sample: "|1|", shows: [:box] },
    "circle" => { sample: "{2}", shows: [:circle] },
    "empty_box" => { sample: "||", shows: [:box] },
    "empty_circle" => { sample: "{}", shows: [:circle] },
    "hatched_box" => { sample: "|/|", shows: [:hatched, :box] },
    "hatched_circle" => { sample: "{/}", shows: [:hatched, :circle] },
    "horizontal_bar" => { sample: "--", shows: [:bar] },
    "arrow_to_r" => { sample: "->", shows: [:arrow_to_r] },
    "arrow_to_l" => { sample: "<-", shows: [:arrow_to_l] },
    "arrow_both" => { sample: "<->", shows: [:arrow_to_l, :arrow_to_r] },
    # the rest of what a label can carry, as rule(:lines) / rule(:markup) /
    # rule(:line) name it
    "bstroke" => { sample: "*->*", shows: [:bstroke] },
    "triangle" => { sample: "^cats", shows: [:triangle] },
    "brackets" => { sample: "#NP", shows: [:brackets] },
    "rectangle" => { sample: "##NP", shows: [:rectangle] },
    "brectangle" => { sample: "###NP", shows: [:brectangle] },
    "region" => { sample: "%NP", shows: [:region] },
    "color_spec" => { sample: "@red:NP", shows: [:color] },
    "path" => { sample: "+>1", shows: [:path], in_label: "t+>1" },
    "tabstop" => { sample: '\t', shows: [:tabstop], in_label: 'HEAD\tnoun' },
    "matrix" => { sample: '#(', shows: [:matrix], in_label: '#(HEAD\tnoun#)' },
    "whole_label_matrix" => { sample: '#(CAT\tS#)', shows: [:matrix] },
    "border" => { sample: "---", shows: [:border], in_label: 'a\n---\nb' },
    "bborder" => { sample: "===", shows: [:bborder], in_label: 'a\n===\nb' },
    # A line break leaves no flag of its own in the evaluated parse — it
    # arrives as one more line of contents — so it is asked about as a count.
    "cr" => { sample: '\n', lines: 2, in_label: 'a\nb' }
  }.freeze

  # The option keys, one line each in every document. tidy_spacing is the
  # deprecated spelling of hspacing and rides in its row.
  OPTION_ALIASES = { tidy_spacing: :hspacing, symmetrization: :tidy }.freeze

  # What the grammar actually enumerates, read from its source so this file
  # cannot quietly fall behind it.
  def grammar_members(rule)
    GRAMMAR[/rule\(:#{rule}\)\s*\{(.*?)\}\n/m, 1].scan(/[a-z_]+/).uniq
  end

  def grammar_references(rule, plumbing)
    grammar_members(rule) - plumbing
  end

  def evaluated_features(obj, acc = [])
    case obj
    when Hash
      obj.each do |k, v|
        case k
        when :decoration then acc.concat(Array(v))
        when :enclosure then acc << v unless v == :none
        when :triangle then acc << :triangle if v
        when :region then acc << :region if v
        when :color then acc << :color if v
        when :matrix then acc << :matrix
        when :path then acc << :path
        when :border then acc << :border
        when :bborder then acc << :bborder
        when :extracr then acc << :extracr
        when :type then acc << v if [:border, :bborder, :extracr].include?(v)
        end
        evaluated_features(v, acc)
      end
    when Array then obj.each { |v| evaluated_features(v, acc) }
    end
    acc
  end

  def parse_features(label)
    parsed = Markup.parse(label)
    return nil unless parsed[:status] == :success

    evaluated_features(parsed).uniq
  end

  # --- completeness -----------------------------------------------------

  def test_every_grammar_feature_has_a_row_here
    features = grammar_members("decoration") +
               grammar_members("shape") +
               grammar_references("lines", %w[triangle maybe as whole label matrix enclosure region color spec line repeat cr eof paths path brectangle rectangle brackets]) +
               %w[triangle brectangle rectangle brackets region color_spec path
                  whole_label_matrix bstroke matrix tabstop border bborder cr]
    missing = features.uniq - SAMPLES.keys
    assert_empty missing, "grammar features with no sample: add a row and document it"
  end

  def test_every_option_has_a_line_in_every_document
    keys = (OPTION_VALUES.keys + NUMERIC_RANGES.keys).uniq - OPTION_ALIASES.keys
    DOCUMENTS.each do |name, text|
      missing = keys.reject { |k| text.include?(k.to_s) }
      assert_empty missing, "#{name}: options with no line"
    end
  end

  # --- the samples mean what they say -----------------------------------

  def test_every_sample_shows_its_feature
    SAMPLES.each do |feature, spec|
      label = spec[:in_label] || spec[:sample]
      if spec[:lines]
        parsed = Markup.parse(label)
        assert_equal :success, parsed[:status], "#{feature}: sample does not parse"
        assert_equal spec[:lines], parsed[:results][:contents].size,
                     "#{feature}: sample #{label.inspect} no longer breaks into #{spec[:lines]} lines"
        next
      end
      shown = parse_features(label)
      refute_nil shown, "#{feature}: sample #{label.inspect} does not parse"
      spec[:shows].each do |name|
        assert_includes shown, name,
                        "#{feature}: sample #{label.inspect} no longer shows #{name}"
      end
    end
  end

  # --- and every document carries them ----------------------------------

  def test_every_document_carries_every_sample
    DOCUMENTS.each do |name, text|
      missing = SAMPLES.reject { |_, spec| text.include?(spec[:sample]) }.keys
      assert_empty missing, "#{name}: samples the reader is never shown"
    end
  end

  # --- traps: accepted, and still surprising ----------------------------

  def check(data, opts = {})
    RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(opts).merge(data: data))
  end

  def test_a_trap_is_by_definition_something_the_tool_accepts
    # Each of these is what the "already means something" section warns about.
    # If one starts being rejected, the warning card comes down: the error
    # message has taken over the job.
    traps = {
      "angle-number is spaces" => "[NP x<3>y]",
      "paired hyphens underline" => "[NP well-made-word]",
      "parentheses are Penn input" => "(S (NP the cat) (VP sat))",
      "apostrophe is typeset curly" => "[N John's]",
      "backslash eats the next character" => '[NP \q]',
      "colour before shade drops the shade" => "[@red:%NP a]",
      "a rule name needs the option on" => '[S\tfoo [A a] [B b]]'
    }
    traps.each do |name, data|
      check(data).draw_svg
    rescue RSTError => e
      flunk "#{name}: #{data.inspect} is rejected (#{e.code}) — no longer a trap, update the reference"
    end
  end

  def test_each_trap_still_produces_the_surprise_it_warns_about
    spaces = check("[NP x<3>y]").draw_svg.gsub(/<[^>]+>/, "")
    assert_includes spaces, "x￭￭￭y", "three spaces, not an angle bracket"

    assert_includes parse_features("well-made-word"), :underline,
                    "the pair of hyphens underlines"

    penn = check("(S (NP the cat) (VP sat))").draw_svg
    assert_includes penn.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten, "NP",
                    "parentheses convert to a tree rather than drawing one leaf"

    assert_includes check("[N John's]").draw_svg, "John’s"

    assert_includes parse_features('\q').inspect, "", "parses"
    eaten = check('[NP \q]').draw_svg
    assert_includes eaten.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten, "q"

    shaded_wrong = check("[@red:%NP a]").draw_svg
    refute_includes shaded_wrong, "fill-opacity", "the shade is dropped"
    assert_includes shaded_wrong.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten.join, "%NP",
                    "and the % is drawn as a character"

    columns = check('[S\tfoo [A a] [B b]]').draw_svg
    assert_includes columns.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten, "foo",
                    "without the derivation option the name is a column"
  end
end
