# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree/markup_parser"
# The escape check below runs a label through the whole of it: what a backslash
# may take is decided on both sides of the parser, and only a drawing shows
# whether the two agree.
require_relative "../lib/rsyntaxtree"

class MarkupParserTest < Minitest::Test
  # The same run of marks, written with every decoration in turn: what the
  # decorations wrap is one thing, and only the wrapping differs.
  DECORATED = { text: [{ chr: "X" }, { chr: "+" }, { chr: "Y" },
                       { chr: "*" }, { chr: "Z" }] }.freeze

  def setup
    @parser = MarkupParser.new
  end

  # Every rule below is asked what it makes of its input, not merely whether it
  # will take it. Parslet raises when a rule refuses, so calling parse and
  # letting it be did check that the grammar still accepts these forms — but
  # nothing checked what came out, and the trees the tests were written against
  # sat in comments where nothing could compare them. The grammar moved on
  # underneath: `brackets` became `enclosure` and grew a region and a colour
  # beside it, a blank line stopped being its own kind of content, and a line
  # break became `extracr`. None of it was noticed here.
  #
  # Positions are dropped. They say where in this particular string a character
  # was found, which changes whenever the input is reworded and says nothing
  # about the rule.
  def plain(tree)
    case tree
    when Hash then tree.to_h { |key, value| [key, plain(value)] }
    when Array then tree.map { |value| plain(value) }
    # Only the slices become text. Everything else the grammar reports is
    # already the value it means — a refusal carries the offset as a number,
    # and turning that into "1" would have it fail against 1.
    when Parslet::Slice then tree.to_s
    else tree
    end
  end

  def test_rule_cr
    assert_equal '\\n', plain(@parser.cr.parse('\\n'))
  end

  def test_rule_brackets
    assert_equal "#", plain(@parser.brackets.parse("#"))
  end

  def test_rule_triangle
    assert_equal "^", plain(@parser.triangle.parse("^"))
  end

  def test_rule_path
    assert_equal({ path: "+12" }, plain(@parser.path.parse("+12")))
    assert_equal({ path: "+>34" }, plain(@parser.path.parse("+>34")))
    assert_equal({ path: "+-87" }, plain(@parser.path.parse("+-87")))
  end

  def test_rule_escaped
    "<>^+*_=~|-".each_char do |chr|
      assert_equal({ chr: chr }, plain(@parser.escaped.parse("\\" + chr)),
                   "a backslash before '#{chr}' did not give the character itself")
    end
  end

  def test_rule_non_escaped
    "abcde12345".each_char do |chr|
      assert_equal({ chr: chr }, plain(@parser.non_escaped.parse(chr)))
    end
  end

  def test_rule_text
    text = "abcde\\<\\>\\^\\+\\*\\_\\=\\~\\|\\-12345"
    assert_equal({ text: "abcde<>^+*_=~|-12345".each_char.map { |c| { chr: c } } },
                 plain(@parser.text.parse(text)))
  end

  # The decorations nest inwards in the order they are written, and what comes
  # out names them from the outside in.
  def test_rule_bolditalic
    assert_equal({ bolditalic: { linethrough: { overline: DECORATED } } },
                 plain(@parser.bolditalic.parse("***~=X\\+Y\\*Z=~***")))
  end

  def test_rule_bold
    assert_equal({ bold: { linethrough: { overline: DECORATED } } },
                 plain(@parser.bold.parse("**~=X\\+Y\\*Z=~**")))
  end

  def test_rule_italic
    assert_equal({ italic: { linethrough: { overline: DECORATED } } },
                 plain(@parser.italic.parse("*~=X\\+Y\\*Z=~*")))
  end

  def test_rule_overline
    assert_equal({ overline: { italic: { linethrough: DECORATED } } },
                 plain(@parser.overline.parse("=*~X\\+Y\\*Z~*=")))
  end

  def test_rule_underline
    assert_equal({ underline: { italic: { linethrough: DECORATED } } },
                 plain(@parser.underline.parse("-*~X\\+Y\\*Z~*-")))
  end

  def test_rule_linethrough
    assert_equal({ linethrough: { italic: { overline: DECORATED } } },
                 plain(@parser.linethrough.parse("~*=X\\+Y\\*Z=*~")))
  end

  def test_rule_superscript
    assert_equal({ superscript: { linethrough: { italic: { overline: DECORATED } } } },
                 plain(@parser.superscript.parse("__~*=X\\+Y\\*Z=*~__")))
  end

  def test_rule_subscript
    assert_equal({ subscript: { linethrough: { italic: { overline: DECORATED } } } },
                 plain(@parser.subscript.parse("_~*=X\\+Y\\*Z=*~_")))
  end

  def test_rule_box
    assert_equal({ box: { linethrough: { italic: { overline: DECORATED } } } },
                 plain(@parser.box.parse("|~*=X\\+Y\\*Z=*~|")))
  end

  # markup takes whichever of them fits, so it gives what box gives.
  def test_rule_markup
    assert_equal({ box: { linethrough: { italic: { overline: DECORATED } } } },
                 plain(@parser.markup.parse("|~*=X\\+Y\\*Z=*~|")))
  end

  def test_rule_border
    assert_equal({ border: "----" }, plain(@parser.border.parse("----")))
  end

  def test_rule_line
    assert_equal({ border: "----" }, plain(@parser.line.parse("----")))
    assert_equal({ line: [{ underline: { text: [{ chr: "u" }] } },
                          { box: { text: [{ chr: "b" }] } },
                          { text: [{ chr: "n" }] }] },
                 plain(@parser.line.parse("-u-|b|n")))
    assert_equal({ extracr: '\\n' }, plain(@parser.line.parse('\\n')))
  end

  def test_rule_lines
    marks = { line: [{ text: [{ chr: "X" }] },
                     { subscript: { text: [{ chr: "Y" }] } },
                     { text: [{ chr: "Z" }] }] }
    assert_equal([{ triangle: "^" },
                  { enclosure: "#", region: nil, color: nil },
                  marks,
                  { paths: [] }],
                 plain(@parser.lines.parse("^#X_Y_Z")))
    # Without the triangle. It is the one maybe that stands on its own, so its
    # absence is a hash holding a single nil, where the three that follow come
    # out as one hash of three names.
    assert_equal([{ triangle: nil },
                  { enclosure: "#", region: nil, color: nil },
                  marks,
                  { paths: [] }],
                 plain(@parser.lines.parse("#X_Y_Z")))
    assert_equal([{ triangle: "^" },
                  { enclosure: nil, region: nil, color: nil },
                  marks,
                  { paths: [{ path: "+1" }, { path: "+>2" }] }],
                 plain(@parser.lines.parse("^X_Y_Z+1+>2")))
    assert_equal([{ triangle: "^" },
                  { enclosure: nil, region: nil, color: nil },
                  { border: "----" },
                  { extracr: '\\n' },
                  marks,
                  { paths: [{ path: "+1" }, { path: "+>2" }] }],
                 plain(@parser.lines.parse('^----\\n\\nX_Y_Z+1+>2')))
  end

  def test_evaluator
    result = plain(Markup.parse('^#----\\n\\nX_Y_Z+1+>2'))
    assert_equal :success, result[:status]
    assert_equal({ enclosure: :brackets,
                   triangle: true,
                   paths: [{ path: "+1" }, { path: "+>2" }],
                   contents: [{ type: :border },
                              { type: :text, elements: [{ text: "　", decoration: [] }] },
                              { type: :text,
                                elements: [{ text: "X", decoration: [] },
                                           { text: "Y", decoration: [:subscript] },
                                           { text: "Z", decoration: [] }] }],
                   color: nil, region: false, region_color: nil },
                 result[:results])

    refused = plain(Markup.parse('!^#----\\n\\nX_Y_Z+1+>2'))
    assert_equal :error, refused[:status]
    assert_equal '!^#----\\n\\nX_Y_Z+1+>2', refused[:text]
    # Where it gave up, counted in characters — a number, not text.
    assert_equal 1, refused[:charpos]
  end

  def test_escaped_percent
    # A backslash-escaped percent is literal text, not a region marker.
    r = Markup.parse("\\%foo")[:results]
    assert_equal false, r[:region]
    text = r[:contents].first[:elements].map { |e| e[:text] }.join
    assert_equal "%foo", text
  end

  def test_escaped_brackets
    text = "[expr [id x] [suffix \\[ [id 2] \\] ] ]"
    @parser = MarkupParser.new
    @parser.parse(text)
    assert true
  end

  def test_region
    # '%' alone: region on, default (nil) color, no node color
    r = Markup.parse("%VP")[:results]
    assert_equal true, r[:region]
    assert_nil r[:region_color]
    assert_nil r[:color]

    # '%@yellow:' : region on with shade color, still no node color
    r = Markup.parse("%@yellow:VP")[:results]
    assert_equal true, r[:region]
    assert_equal "yellow", r[:region_color]
    assert_nil r[:color]

    # region shade color and node text color are independent
    r = Markup.parse("%@yellow:@blue:VP")[:results]
    assert_equal "yellow", r[:region_color]
    assert_equal "blue", r[:color]

    # hex shade color keeps the leading '#'
    r = Markup.parse("%@#ffcc00:VP")[:results]
    assert_equal "#ffcc00", r[:region_color]

    # no '%' : region off, default value
    r = Markup.parse("@blue:VP")[:results]
    assert_equal false, r[:region]
    assert_nil r[:region_color]

    # region composes with triangle and enclosure
    r = Markup.parse("^##%@red:NP")[:results]
    assert_equal true, r[:region]
    assert_equal "red", r[:region_color]
    assert_equal true, r[:triangle]
    assert_equal :rectangle, r[:enclosure]
  end
  # What a backslash may take is written down twice: once in the grammar, as
  # Markup's `escaped` rule, and once in the tokenizer that cuts the input into
  # labels, which decides which backslashes to keep. The two drifted — '#' was
  # in the grammar and not in the tokenizer, so `\#` reached the grammar as a
  # bare '#', which opens an enclosure: a label written with a hash in it lost
  # the hash, and what followed went inside brackets instead.
  #
  # Asked of the drawing rather than of either list, so a character that falls
  # out of one of them says so here.
  # The backslash itself is on the list: `\\` is how a label carries one.
  ESCAPABLE = "#<>{}^+*_=~|-[]%\\"

  ESCAPABLE.each_char do |character|
    define_method("test_a_backslash_makes_#{character.ord}_literal") do
      svg = RSyntaxTree::RSGenerator.new(
        DEFAULT_OPTS.merge(data: "[X \\#{character}a]")
      ).draw_svg
      drawn = svg.scan(%r{<tspan[^>]*>([^<]*)</tspan>}).flatten
                 .map { |t| CGI.unescapeHTML(t) }.reject { |t| t.strip.empty? }
      assert_equal "#{character}a", drawn.last,
                   "a backslash did not make '#{character}' literal"
    end
  end

end
