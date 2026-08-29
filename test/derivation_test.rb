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
  # The rule names are set smaller than the categories.
  def initialize(*)
    super
    @fontsize_guard = DEFAULT_OPTS[:fontsize] * FONT_SCALING
  end

  def draw(data, **opts)
    RSyntaxTree::RSGenerator.new(
      DEFAULT_OPTS.merge(fontstyle: "serif", color: "off", leafstyle: "nothing",
                         direction: "btt", derivation: "on", vheight: 0.7,
                         data: data).merge(opts)
    ).draw_svg
  end

  # A rule name names the step that produced a node from its daughters, so a
  # node with no daughters names no rule, and what looked like a name is a
  # column of the label like any other. Turning the option on used to delete it:
  # the label is read before the tree is built, the name was taken out, and then
  # there was no rule to draw it beside.
  def test_a_node_with_no_daughters_keeps_its_columns
    labels = ->(svg) { svg.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten.reject(&:empty?) }
    off = labels.call(draw("[S [A\\tfoo] [B b]]", derivation: "off", direction: "ttb"))
    on = labels.call(draw("[S [A\\tfoo] [B b]]"))

    assert_includes off, "foo", "the column is drawn when the option is off"
    assert_includes on, "foo", "and the option must not delete it"
  end

  # Where there is a step, the name still leaves the label and is drawn beside
  # the rule instead.
  def test_a_node_with_daughters_still_names_its_rule
    svg = draw("[A\\tfoo [B b] [C c]]")

    refute_includes svg.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten, "foo",
                    "the name is no longer a column"
    assert_includes svg.scan(%r{<text[^>]*>([^<]+)</text>}).flatten.map(&:strip), "foo",
                    "it is drawn beside the rule"
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

  # The name sits on its rule. Text is placed by its baseline and what rises
  # above that differs with what is written, so the offset is measured from the
  # ink; taken as a fraction of the line height instead, every name sat low.
  def test_the_rule_name_is_centred_on_its_rule
    svg = draw('[S\t>B [NP\t<Φ> [D a] [N b]] [VP c]]')
    rules = svg.scan(/<line[^>]*x2='([\d.]+)' y1='([\d.]+)' [^>]*y2='([\d.]+)'/)
    rules = svg.scan(/<line[^>]*x1='[\d.]+' y1='([\d.]+)' x2='([\d.]+)' y2='([\d.]+)'/)
               .select { |y1, _, y2| (y1.to_f - y2.to_f).abs < 0.01 }
               .map { |y1, x2, _| [x2.to_f, y1.to_f] }
    names = svg.scan(/font-size:\s*([\d.]+)px[^>]*x='([\d.]+)' y='([\d.]+)'/)
               .select { |size,| size.to_f < @fontsize_guard }
    refute_empty names
    names.each do |_, x, y|
      rule_y = rules.min_by { |rx, _| (rx - x.to_f).abs }&.last
      refute_nil rule_y
      # The marks straddle the rule: the baseline sits a little below it, by
      # less than the height of the marks themselves.
      assert_operator y.to_f, :>, rule_y
      assert_operator y.to_f - rule_y, :<, 14.0
    end
  end

  # Every premise is given at the start, so the words stand in one row. Placed
  # by depth from the root instead, a branch that combines in fewer steps
  # leaves its word higher than the rest and the top of the figure is a
  # staircase. The relative clause is where this shows: its branches are three
  # steps apart.
  def test_the_words_stand_in_one_row
    ALL.each do |name, data|
      # Rows are read off the drawing, where a label of several lines puts a
      # line in each of them. That would count one label as many and the
      # reading would be wrong, so the check is only good for labels of one
      # line — which is what a derivation of categories is.
      refute_includes data, '\n', "#{name}: rows cannot be counted this way"
      svg = draw(data)
      ys = svg.scan(/<tspan x='[\d.]+' y='([\d.]+)'/).flatten.map(&:to_f)
      top = ys.min
      words = ys.count { |y| (y - top).abs < 1.0 }
      # However many words the derivation has, they are all on that row: no
      # other row can hold more than the top one.
      rows = ys.group_by { |y| y.round }.values.map(&:size)
      assert_equal rows.max, words, "#{name}: the words are not all in the top row"
    end
  end

  # The name is drawn past the end of its rule, and the packing has to leave
  # room for it. Pulled tight against the next subtree, two steps read as one
  # long rule with a mark in the middle of it.
  #
  # Drawn with tidy off there is slack between the subtrees anyway and nothing
  # here is ever tight; it is tidy that closes the gap and so tidy the room has
  # to survive. The gallery draws these on low for the same reason.
  def test_a_rule_name_does_not_touch_the_next_rule
    svg = draw(APPLICATION, tidy: "low")
    rules = svg.scan(/<line[^>]*x1='([\d.]+)' y1='([\d.]+)' x2='([\d.]+)' y2='([\d.]+)'/)
               .select { |_, y1, _, y2| (y1.to_f - y2.to_f).abs < 0.01 }
               .map { |x1, y, x2, _| [y.to_f.round, x1.to_f, x2.to_f] }
    names = svg.scan(/font-size:\s*([\d.]+)px[^>]*x='([\d.]+)' y='([\d.]+)'/)
               .select { |size,| size.to_f < @fontsize_guard }
               .map { |_, x, y| [y.to_f.round, x.to_f] }
    checked = 0
    rules.group_by(&:first).each_value do |row|
      next if row.size < 2

      row.sort_by! { |_, x1, _| x1 }
      row.each_cons(2) do |(y, _, left_end), (_, right_start, _)|
        name = names.find { |ny, nx| (ny - y).abs < 30 && nx > left_end && nx < right_start }
        next unless name

        # The name is about fourteen wide here. Measured from where it starts,
        # anything under twenty-four leaves it all but touching what follows;
        # unpacked for the name it comes out around thirty.
        assert_operator right_start - name.last, :>, 24.0,
                        "a rule name is pressed against the rule that follows it"
        checked += 1
      end
    end
    assert_operator checked, :>, 0, "no neighbouring rules were found to check"
  end

  # The name is the one thing drawn outside any element's own box, so the
  # canvas has to be told where it ends. Measured from the boxes alone, the
  # last step's name ran off the edge of the image and was cut in half.
  def test_a_long_rule_name_stays_inside_the_canvas
    ["btt", "ttb"].each do |dir|
      ['[S\t>BN-compose-long-name [NP the cat] [VP sat]]',
       '[A [B x] [C\t>VERY-LONG-COMPOSITION [D y]]]'].each do |src|
        svg = draw(src, direction: dir)
        canvas = svg[/<svg[^>]*>/][/\bwidth=['"]([\d.]+)/, 1].to_f
        names = svg.scan(/font-size:\s*([\d.]+)px[^>]*x='([\d.]+)' y='[\d.]+'[^>]*>([^<]*)</)
                   .select { |size,| size.to_f < @fontsize_guard }
        refute_empty names
        names.each do |size, x, text|
          # The name is set in the same face as everything else, so half its
          # point size per character is a floor on how wide it is, never an
          # overestimate.
          least = text.length * size.to_f / 2
          assert_operator x.to_f + least, :<, canvas,
                          "#{dir}: the rule name runs off the canvas"
        end
      end
    end
  end

  # Hiding the default connectors draws them in the background colour rather
  # than skipping them, and a derivation's rules go the same way: the figure
  # comes out as rows of categories with nothing joining them.
  def test_hiding_the_connectors_is_refused
    e = assert_raises(RSTError) { draw(APPLICATION, hide_default_connectors: "on") }
    assert_equal :invalid_option, e.code
    assert_includes e.hint, "derivation"
  end

  # Written without the option on, the label is unclosed markup and the advice
  # is about spaces — the opposite of what the writer needs. The combinators
  # are made of the same characters as the whitespace marker, so the reading
  # has to be settled before that one is offered.
  def test_a_derivation_written_without_the_option_is_told_so
    e = assert_raises(RSTError) { draw(APPLICATION, derivation: "off") }
    assert_equal :rule_name_without_derivation, e.code
    assert_includes e.hint, "derivation"
  end

  # A break the writer escaped is theirs. Split on it as well, the label lost
  # everything after it and nothing was drawn in its place.
  def test_an_escaped_column_break_is_left_in_the_label
    assert_includes draw('[X a\\\\tb [Y d]]'), "a\\tb"
  end

  # Only a mother has a step under it for a name to sit beside. Taken off a
  # leaf, whose `a\tb` is a row of two columns, the second column vanished.
  def test_a_leaf_keeps_both_of_its_columns
    svg = draw('[X [w1 a\tL] [w2 b]]')
    %w[a L].each { |t| assert_includes svg, ">#{t}<" }
  end

  # A category may be a feature structure, which is how a derivation is written
  # where the categories carry features. The breaks inside the matrix are its
  # own columns; the one that names the rule is the break at the top level of
  # the label. Counted together, a matrix category could name no rule at all
  # and the label was refused — with advice to turn on the option that was
  # already on.
  def test_a_matrix_category_can_name_its_rule
    svg = draw('[#(CAT\tS#)\t< [#(CAT\tNP#)\t> [#(CAT\tNP/N#) the] ' \
               '[#(CAT\tN#) dog]] [#(CAT\tS\\\\NP#) bit]]', hyphen: "literal")
    assert_includes svg, "&lt;"
    assert_includes svg, "CAT"
    assert_equal 0, slanted_lines(svg)
  end

  # Rows are levelled after the layout is turned over. Turning it over sets
  # each box against its own bottom edge, so a matrix — taller than the
  # categories beside it — stood proud of its row and took the rule drawn to it
  # up with it, leaving two steps of the same derivation at two heights.
  def test_a_tall_category_does_not_lift_its_rule_off_the_row
    %w[btt ttb].each do |direction|
      svg = draw('[S\t< [#(CAT\tNP\nNUM\tsg#)\t> [NP/N the] [N dog]] ' \
                 '[S\\\\NP\t> [(S\\\\NP)/NP bit] [NP John]]]',
                 hyphen: "literal", direction: direction)
      heights = rule_heights(svg)
      # Four words, two steps over them, then one step over both: three heights.
      assert_equal 3, heights.size,
                   "#{direction}: the rules stand at #{heights.size} heights, not three"
    end
  end

  # Where all the categories are one line, every row is the same height, so the
  # rules come at an even pitch down the page. Placing a rule from its row
  # rather than from its label must leave that pitch alone — a derivation of
  # plain categories is what the gallery holds, and what most readers write.
  def test_rules_come_at_an_even_pitch_when_the_rows_are_of_a_height
    %w[btt ttb].each do |direction|
      heights = rule_heights(draw(APPLICATION, direction: direction))
      assert_operator heights.size, :>=, 3
      pitches = heights.each_cons(2).map { |a, b| (b - a).round(1) }
      assert_equal 1, pitches.uniq.size,
                   "#{direction}: the rules come at #{pitches.uniq.inspect} apart, not one pitch"
    end
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
  def test_json_records_the_rules_as_rules
    require "json"
    doc = JSON.parse(
      RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: APPLICATION, format: "json", leafstyle: "nothing",
                           direction: "btt", derivation: "on")
      ).draw_json
    )
    assert_equal true, doc["meta"]["source"]["params"]["derivation"]
    assert_equal "btt", doc["geometry"]["direction"]
    assert_equal ["rule"], doc["edges"].map { |e| e["connector"] }.uniq
  end

  private

  # The heights the horizontal rules stand at, in order down the page.
  def rule_heights(svg)
    svg.scan(/<line[^>]*y1='([\d.]+)' x2='[\d.]+' y2='([\d.]+)'/)
       .select { |y1, y2| (y1.to_f - y2.to_f).abs < 0.01 }
       .map { |y1,| y1.to_f.round(1) }.uniq.sort
  end

  # A rule is horizontal: both ends share a y. Anything else is a connector
  # the derivation was supposed to replace.
  def slanted_lines(svg)
    svg.scan(/<line[^>]*y1='([\d.]+)'[^>]*y2='([\d.]+)'/)
       .count { |y1, y2| (y1.to_f - y2.to_f).abs > 0.01 }
  end
end
