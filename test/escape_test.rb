# frozen_string_literal: true

require "minitest/autorun"
require "cgi"
require_relative "../lib/rsyntaxtree"

# RSyntaxTree.escape promises that its result draws as the text it was
# given. That promise is checked the only way it can be: each result is
# drawn, and the text read back off the figure is compared with the input.
# The escaping rules are not restated here — a second copy of them would
# only agree with the first until one of them changed.
class EscapeTest < Minitest::Test
  # The text a figure shows, line by line, read off its SVG. Every tspan is
  # collected with its position; those on one baseline form one line, in
  # order from the left; lines follow one another from the top.
  def lines_drawn(svg)
    chunks = svg.scan(/<text[^>]*>(.*?)<\/text>/m).flatten.flat_map do |inner|
      # A tspan carrying a y starts a line; what follows it until the next
      # such tspan — nested spans included — is that line's text.
      inner.split(/(?=<tspan[^>]*\by=')/).filter_map do |chunk|
        y = chunk[/\A<tspan[^>]*\by='([\d.]+)'/, 1]
        x = chunk[/\A<tspan[^>]*\bx='([\d.]+)'/, 1]
        next if y.nil? || x.nil?

        # The source breaks its lines after a tspan; those breaks are not
        # text.
        text = CGI.unescapeHTML(chunk.gsub(/<[^>]+>/, "")).gsub(WHITESPACE_BLOCK, " ").delete("\n")
        [y.to_f.round(1), x.to_f, text]
      end
    end
    chunks.group_by(&:first).sort.map { |_y, row| row.sort_by { |c| c[1] }.map(&:last).join }
  end

  MARKER = "Ｋ" # a cell that stands beside the text under test, never inside it

  # The text under test, as the figure shows it, given the notation and the
  # context the text was escaped for.
  def drawn(escaped, as:, hyphen:)
    data = case as
           when :word, :phrase then "[S [X #{escaped}]]"
           when :label         then "[S [#{escaped} x]]"
           when :cell          then "[S [X #(#{MARKER}\\t#{escaped}#)]]"
           end
    svg = RSyntaxTree::RSGenerator.new(data: data, format: "svg", hyphen: hyphen.to_s).draw_svg
    lines = lines_drawn(svg).reject { |l| %w[S X x].include?(l.strip) }
    lines = lines.map { |l| l.delete_prefix(MARKER) } if as == :cell
    lines.join("\n").strip
  end

  # What the figure should show for +text+: its apostrophes curly unless
  # kept; in a phrase, whitespace runs collapse to one space; in a word,
  # each whitespace character is one space.
  def expected(text, as:, apostrophe:)
    e = apostrophe == :curly ? text.gsub("'", "’") : text
    as == :phrase ? e.split(/\s+/).reject(&:empty?).join(" ") : e.gsub(/[\t\r\n]/, " ").strip
  end

  # Every character the notation reads as markup, alone and in company,
  # the whitespace kinds, and text that has tripped a program before.
  CORPUS = [
    "Tom's", "well-known", "e-mail", "-", "--", "===", "@", "@red:x", "5%", "%",
    "[see", "#42", "#(x", "#", "<ok>", "<>", "<3>", "a*b", "c_d", "{x}", "|y|",
    "|/|", "~z~", "=w=", "^top", "^^", "&", "co.", "back\\slash", "\\n", "\\t",
    "C++", "x+1", "2+2", "v+>1", "a+-1", "+1", "x--y", "->", "<-", "<->",
    "**bold**", "a b", "a  b", "日本語", "⟨NP⟩", "λx.P(x)", "¥100", "x\\+1",
    "100%", "it's", "'", "a'b'c", "wait --- no", "x---y",
    # The web interface's transport spellings, which the reader turns back
    # into the characters they stand for unless told otherwise.
    "-AMP-", "-PRIME-", "-OABRACKET-",
    # An ideographic space and a no-break space are characters, not word
    # breaks: a phrase keeps them and a word does not turn them into <>.
    "a\u3000b", "x\u00a0y"
  ].freeze

  # Under hyphen: literal a line of nothing but hyphens is the horizontal
  # rule, and there is no notation for the text "---" in that mode.
  RULE_LINES = ["---"].freeze

  def test_every_corpus_text_draws_as_itself_in_every_context
    %i[word label cell phrase].each do |as|
      %i[markup literal].each do |hyphen|
        %i[curly keep].each do |apostrophe|
          CORPUS.each do |text|
            escaped = RSyntaxTree.escape(text, as: as, hyphen: hyphen, apostrophe: apostrophe)
            assert_equal expected(text, as: as, apostrophe: apostrophe),
                         drawn(escaped, as: as, hyphen: hyphen),
                         "#{text.inspect} as #{as}, hyphen #{hyphen}, apostrophe #{apostrophe} " \
                         "(escaped: #{escaped.inspect})"
          end
        end
      end
    end
  end

  # Under hyphen: literal there is no notation for a line of hyphens, so
  # escape says so instead of returning notation that draws nothing.
  def test_a_line_of_hyphens_is_refused_under_literal
    ["---", "----"].each do |text|
      %i[word label cell].each do |as|
        assert_raises(ArgumentError, "#{text} as #{as}") { RSyntaxTree.escape(text, as: as, hyphen: :literal) }
      end
      assert_raises(ArgumentError) { RSyntaxTree.escape(text, as: :phrase, hyphen: :literal) }
    end
    # A rule is a whole line: hyphens with company on the line are text.
    assert_equal "wait --- no", RSyntaxTree.escape("wait --- no", as: :phrase, hyphen: :literal)
    assert_equal "--", RSyntaxTree.escape("--", hyphen: :literal)
    # A multi-line label or cell is refused when any of its lines is one.
    assert_raises(ArgumentError) { RSyntaxTree.escape("a\n---\nb", as: :label, hyphen: :literal) }
    assert_raises(ArgumentError) { RSyntaxTree.escape("a\n---", as: :cell, hyphen: :literal) }
    # In a word a newline is a space, so the hyphens have company.
    assert_equal "a<>---<>b", RSyntaxTree.escape("a\n---\nb", as: :word, hyphen: :literal)
  end

  def test_a_carriage_return_line_feed_is_one_space_in_a_word
    assert_equal "a<>b", RSyntaxTree.escape("a\r\nb")
    assert_equal "a\\nb", RSyntaxTree.escape("a\r\nb", as: :label)
  end

  def test_a_line_of_hyphens_draws_as_itself_under_markup
    RULE_LINES.each do |text|
      %i[word label cell].each do |as|
        escaped = RSyntaxTree.escape(text, as: as, hyphen: :markup)
        assert_equal text, drawn(escaped, as: as, hyphen: :markup)
      end
    end
  end

  def test_tabs_and_newlines_become_breaks_in_a_cell_and_a_label
    assert_equal "a\\tb\\nc", RSyntaxTree.escape("a\tb\nc", as: :cell)
    assert_equal "a<>b\\nc", RSyntaxTree.escape("a\tb\nc", as: :label)
    assert_equal "a<>b<>c", RSyntaxTree.escape("a\tb\nc", as: :word)
    # A newline in a cell is a row break, which the figure shows as a line.
    assert_equal "a\nb", drawn(RSyntaxTree.escape("a\nb", as: :cell), as: :cell, hyphen: :markup)
    assert_equal "a\nb", drawn(RSyntaxTree.escape("a\nb", as: :label), as: :label, hyphen: :markup)
  end

  def test_a_phrase_keeps_its_words_apart_and_gets_a_triangle
    escaped = RSyntaxTree.escape("the well-known dog", as: :phrase)
    assert_equal "the well\\-known dog", escaped
    svg = RSyntaxTree::RSGenerator.new(data: "[S [X #{escaped}]]", format: "svg").draw_svg
    assert_includes svg, "<polygon", "a leaf of several words is joined by a triangle"
  end

  def test_the_hyphen_mode_must_be_named_because_no_escape_serves_both
    assert_equal "e\\-mail", RSyntaxTree.escape("e-mail", hyphen: :markup)
    assert_equal "e-mail", RSyntaxTree.escape("e-mail", hyphen: :literal)
  end

  def test_the_arguments_are_checked
    assert_raises(ArgumentError) { RSyntaxTree.escape("x", as: :sentence) }
    assert_raises(ArgumentError) { RSyntaxTree.escape("x", hyphen: :both) }
    assert_raises(ArgumentError) { RSyntaxTree.escape("x", apostrophe: :smart) }
  end

  # The two notation changes escape relies on, each checked at the drawing.
  def test_an_escaped_plus_before_digits_is_text_not_a_path
    %w[x\\+1 C\\+\\+11 2\\+2].each do |label|
      svg = RSyntaxTree::RSGenerator.new(data: "[S [X #{label}]]", format: "svg").draw_svg
      assert_equal label.delete("\\"), lines_drawn(svg).last
    end
    # An escaped backslash before a marker leaves the marker a marker.
    svg = RSyntaxTree::RSGenerator.new(data: "[S [X back\\\\+1] [Y y+1]]", format: "svg").draw_svg
    assert_includes lines_drawn(svg).join, "back\\"
    assert_operator svg.scan("<path").size, :>, 1, "the path between X and Y is drawn"
  end

  def test_an_escaped_apostrophe_stays_straight
    svg = RSyntaxTree::RSGenerator.new(data: "[S [X Tom\\'s]]", format: "svg").draw_svg
    assert_equal "Tom's", lines_drawn(svg).last
    svg = RSyntaxTree::RSGenerator.new(data: "[S [X Tom's]]", format: "svg").draw_svg
    assert_equal "Tom’s", lines_drawn(svg).last
  end

  def test_split_path_counts_the_backslashes_before_a_marker
    assert_equal ["x\\+1", ""], RSyntaxTree::Element.split_path("x\\+1")
    assert_equal ["back\\\\", "+1"], RSyntaxTree::Element.split_path("back\\\\+1")
    assert_equal ["x\\+1", "+2"], RSyntaxTree::Element.split_path("x\\+1+2")
    assert_equal ["NP", "+>1+2"], RSyntaxTree::Element.split_path("NP+>1+2")
    assert_equal ["+1", ""], RSyntaxTree::Element.split_path("+1"), "nothing to draw a path from"
  end
end
