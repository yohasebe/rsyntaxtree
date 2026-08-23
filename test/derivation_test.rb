# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"

# A derivation is a tree drawn the way a derivation is written: the words at
# the top, each step a rule across everything it combines, the result last.
# The four here are the canonical shapes — application, type-raising with
# composition, a relative clause, and coordination — and they are what the
# drawing was built against.
class DerivationTest < Minitest::Test
  def draw(data, **opts)
    RSyntaxTree::RSGenerator.new(
      DEFAULT_OPTS.merge(fontstyle: "serif", color: "off", leafstyle: "nothing",
                         direction: "btt", derivation: "on", vheight: 0.7,
                         data: data).merge(opts)
    ).draw_svg
  end

  # Two premises joined, twice, then the two results joined.
  APPLICATION = '[S\t< [NP\t> [NP/N the] [N dog]] ' \
                '[S\\\\NP\t> [(S\\\\NP)/NP bit] [NP John]]]'

  # A step with one premise (type-raising) beside steps with two.
  RAISING = '[S\t> [S/NP\t>B [S/(S\\\\NP)\t>T [NP\t> [NP/N the] [N dog]]] ' \
            '[(S\\\\NP)/NP bit]] [NP John]]'

  # The construction CCG exists for: a dependency that is not bounded.
  RELATIVE = '[NP\t> [NP/N the] [N\t< [N man] [N\\\\N\t> [(N\\\\N)/(S/NP) that] ' \
             '[S/NP\t>B [S/(S\\\\NP)\t>T [NP Mary]] [(S\\\\NP)/NP saw]]]]]'

  # Three premises under one rule, and a combinator that is not a bare arrow.
  COORDINATION = '[S\t> [S/NP\t<Φ> [S/NP\t>B [S/(S\\\\NP)\t>T [NP Mary]] ' \
                 '[(S\\\\NP)/NP likes]] [conj and] ' \
                 '[S/NP\t>B [S/(S\\\\NP)\t>T [NP Bill]] [(S\\\\NP)/NP hates]]] [NP London]]'

  ALL = { application: APPLICATION, raising: RAISING,
          relative: RELATIVE, coordination: COORDINATION }.freeze

  ALL.each do |name, data|
    define_method "test_#{name}_draws" do
      assert_match(/<svg/, draw(data))
    end
  end

  # The rule replaces the lines. A derivation with a line left in it is the
  # tree it was drawn from, not a derivation.
  def test_a_derivation_has_no_slanted_lines
    ALL.each do |name, data|
      slanted = slanted_lines(draw(data))
      assert_equal 0, slanted, "#{name} was drawn with slanted lines"
    end
  end

  # The rule covers everything the step combines. Read off the drawing: the
  # widest rule has to reach at least as wide as the whole figure's text.
  def test_the_last_rule_spans_the_whole_derivation
    svg = draw(APPLICATION)
    widths = svg.scan(/<line[^>]*x1='([\d.]+)'[^>]*x2='([\d.]+)'/)
                .map { |x1, x2| (x2.to_f - x1.to_f).abs }
    refute_empty widths
    xs = svg.scan(/<tspan x='([\d.]+)'/).flatten.map(&:to_f)
    text_span = xs.max - xs.min
    assert_operator widths.max, :>=, text_span,
                    "no rule reaches across the derivation"
  end

  # Turning it off gives the tree back.
  def test_without_derivation_the_lines_return
    plain = "[S [NP [NP/N the] [N dog]] [VP bit]]"
    assert_operator slanted_lines(draw(plain, derivation: "off")), :>, 0
    assert_equal 0, slanted_lines(draw(plain))
  end

  # btt is the layout turned over: the root ends up below the leaves.
  def test_btt_puts_the_root_last
    top = ->(dir) do
      svg = draw("[S [NP a] [VP b]]", direction: dir, derivation: "off")
      svg.scan(/<tspan[^>]*y='([\d.]+)'[^>]*>([^<]*)</).to_h { |y, t| [t.strip, y.to_f] }
    end
    ttb = top.call("ttb")
    btt = top.call("btt")
    assert_operator ttb["S"], :<, ttb["a"], "ttb should put the root above the leaves"
    assert_operator btt["S"], :>, btt["a"], "btt should put the root below the leaves"
  end

  # Turned over on its own, without the rules, the connectors have to change
  # ends: the parent is now the lower of the two. Keeping the top-to-bottom
  # ends drew every line back up through both labels.
  def test_btt_connectors_run_between_the_labels
    svg = draw("[S [NP a] [VP b]]", direction: "btt", derivation: "off")
    text_y = svg.scan(/<tspan x='[\d.]+' y='([\d.]+)'[^>]*>([^<]*)</)
                .to_h { |y, t| [t.strip, y.to_f] }
    svg.scan(/<line[^>]*y1='([\d.]+)'[^>]*y2='([\d.]+)'/).each do |y1, y2|
      top, bottom = [y1.to_f, y2.to_f].minmax
      assert_operator top, :>, text_y["a"], "a connector starts above the leaves"
      assert_operator bottom, :<, text_y["S"] + 40, "a connector runs past the root"
    end
  end

  # Both directions and both connector styles: what changes is which edge of
  # each box the line leaves from, and nothing else.
  def test_every_direction_and_connector_combination_draws
    [["ttb", "off"], ["ttb", "on"], ["btt", "off"], ["btt", "on"]].each do |dir, der|
      [["off"], ["on"]].each do |poly,|
        svg = draw("[S [NP [D the] [N dog]] [VP bit]]",
                   direction: dir, derivation: der, polyline: poly)
        assert_match(/<svg/, svg, "direction=#{dir} derivation=#{der} polyline=#{poly}")
      end
    end
  end

  # The rule's name comes out of the label and goes beside the rule, so it is
  # drawn once and is not part of the category.
  def test_the_rule_name_leaves_the_label
    with_name = draw('[S\t>B [NP a] [VP b]]')
    assert_includes with_name, "&gt;B"
    assert_equal 1, with_name.scan(/&gt;B/).size
  end

  # A feature matrix is many lines and many columns. Reading its last column as
  # a rule name would take a value out of the matrix.
  def test_a_matrix_label_keeps_all_its_columns
    svg = draw('[S [#HEAD\tverb\nSPR\t⟨⟩] [NP a]]')
    assert_includes svg, "HEAD"
    assert_includes svg, "verb"
    assert_includes svg, "SPR"
  end

  # A derivation runs down the page, so there is nothing for a rule to span
  # when the tree runs across it.
  def test_left_to_right_is_refused
    e = assert_raises(RSTError) { draw(APPLICATION, direction: "ltr") }
    assert_equal :invalid_option, e.code
    assert_includes e.hint, "ttb"
  end

  # forest draws a tree from the root down, joining each daughter with its own
  # edge. What it would emit here is a different figure, not this one with
  # something missing, so it says so.
  def test_tikz_refuses_rather_than_drawing_a_tree
    [{ derivation: "on", direction: "ttb" }, { derivation: "off", direction: "btt" }].each do |opts|
      e = assert_raises(RSTError) do
        RSyntaxTree::RSGenerator.new(
          DEFAULT_OPTS.merge(data: "[S [NP a] [VP b]]", format: "tikz").merge(opts)
        ).draw_tikz
      end
      assert_equal :invalid_option, e.code
    end
  end

  # The interchange format states that it carries how the figure was drawn.
  def test_lsif_records_the_rules_as_rules
    require "json"
    lsif = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: APPLICATION, format: "lsif", leafstyle: "nothing",
                           direction: "btt", derivation: "on")
      ).draw_lsif
    )
    assert_equal true, lsif["meta"]["source"]["params"]["derivation"]
    assert_equal "btt", lsif["geometry"]["direction"]
    assert_equal ["rule"], lsif["edges"].map { |e| e["connector"] }.uniq
  end

  private

  # A rule is horizontal: both ends share a y. Anything else is a connector
  # the derivation was supposed to replace.
  def slanted_lines(svg)
    svg.scan(/<line[^>]*y1='([\d.]+)'[^>]*y2='([\d.]+)'/)
       .count { |y1, y2| (y1.to_f - y2.to_f).abs > 0.01 }
  end
end
