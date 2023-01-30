# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require_relative "../lib/rsyntaxtree/markup_parser"

class MarkupParserTest < Minitest::Test
  def setup
    @parser = MarkupParser.new
  end

  def test_rule_cr
    @parser.cr.parse('\\n')
    # "\\n"@0
  end

  def test_rule_brackets
    @parser.brackets.parse('#')
    # "#"@0
  end

  def test_rule_triangle
    @parser.triangle.parse('^')
    # "^"@0
  end

  def test_rule_path
    @parser.path.parse('+12')
    # {:path=>"+12"@0}
    @parser.path.parse('+>34')
    # {:path=>"+>34"@0}d
    @parser.path.parse('+-87')
    # {:path=>"+-87"@0}d
  end

  def test_rule_escaped
    "<>^+*_=~|-".split(//).each do |chr|
      @parser.escaped.parse('\\' + chr)
      # {:chr=>"<"@1}
      # {:chr=>">"@1}
      # {:chr=>"^"@1}
      # {:chr=>"+"@1}
      # {:chr=>"*"@1}
      # {:chr=>"_"@1}
      # {:chr=>"="@1}
      # {:chr=>"~"@1}
      # {:chr=>"|"@1}
      # {:chr=>"-"@1}
    end
  end

  def test_rule_non_escaped
    "abcde12345".split(//).each do |chr|
      @parser.non_escaped.parse(chr)
      # {:chr=>"a"@0}
      # {:chr=>"b"@0}
      # {:chr=>"c"@0}
      # {:chr=>"d"@0}
      # {:chr=>"e"@0}
      # {:chr=>"1"@0}
      # {:chr=>"2"@0}
      # {:chr=>"3"@0}
      # {:chr=>"4"@0}
      # {:chr=>"5"@0}
    end
  end

  def test_rule_text
    text = "abcde\\<\\>\\^\\+\\*\\_\\=\\~\\|\\-12345"
    @parser.text.parse(text)
    # {:text=>
    #  [{:chr=>"a"@0},
    #   {:chr=>"b"@1},
    #   {:chr=>"c"@2},
    #   {:chr=>"d"@3},
    #   {:chr=>"e"@4},
    #   {:chr=>"<"@6},
    #   {:chr=>">"@8},
    #   {:chr=>"^"@10},
    #   {:chr=>"+"@12},
    #   {:chr=>"*"@14},
    #   {:chr=>"_"@16},
    #   {:chr=>"="@18},
    #   {:chr=>"~"@20},
    #   {:chr=>"|"@22},
    #   {:chr=>"-"@24},
    #   {:chr=>"1"@25},
    #   {:chr=>"2"@26},
    #   {:chr=>"3"@27},
    #   {:chr=>"4"@28},
    #   {:chr=>"5"@29}]}
  end

  def test_rule_bolditalic
    text = "***~=X\\+Y\\*Z=~***"
    @parser.bolditalic.parse(text)
    # {:bolditalic=>{:linethrough=>{:overline=>{:text=>[{:chr=>"X"@5}, {:chr=>"+"@7}, {:chr=>"Y"@8}, {:chr=>"*"@10}, {:chr=>"Z"@11}]}}}}
  end

  def test_rule_bold
    text = "**~=X\\+Y\\*Z=~**"
    @parser.bold.parse(text)
    # {:bold=>{:linethrough=>{:overline=>{:text=>[{:chr=>"X"@4}, {:chr=>"+"@6}, {:chr=>"Y"@7}, {:chr=>"*"@9}, {:chr=>"Z"@10}]}}}}
  end

  def test_rule_italic
    text = "*~=X\\+Y\\*Z=~*"
    @parser.italic.parse(text)
    # {:italic=>{:linethrough=>{:overline=>{:text=>[{:chr=>"X"@3}, {:chr=>"+"@5}, {:chr=>"Y"@6}, {:chr=>"*"@8}, {:chr=>"Z"@9}]}}}}
  end

  def test_rule_overline
    text = "=*~X\\+Y\\*Z~*="
    @parser.overline.parse(text)
    # {:overline=> ...}
  end

  def test_rule_underline
    text = "-*~X\\+Y\\*Z~*-"
    @parser.underline.parse(text)
    # {:underline=> ...}
  end

  def test_rule_linethrough
    text = "~*=X\\+Y\\*Z=*~"
    @parser.linethrough.parse(text)
    # {:linethrough=> ...}
  end

  def test_rule_superscript
    text = "__~*=X\\+Y\\*Z=*~__"
    @parser.superscript.parse(text)
    # {:superscript=> ...}
  end

  def test_rule_subscript
    text = "_~*=X\\+Y\\*Z=*~_"
    @parser.subscript.parse(text)
    # {:subscript=> ...}
  end

  def test_rule_box
    text = "|~*=X\\+Y\\*Z=*~|"
    @parser.box.parse(text)
    # {:box=> ...}
  end

  def test_rule_markup
    text = "|~*=X\\+Y\\*Z=*~|"
    @parser.markup.parse(text)
    # {:box=>{:linethrough=>{:italic=>{:overline=>{:text=>[
    # {:chr=>"X"@4}, {:chr=>"+"@6}, {:chr=>"Y"@7}, {:chr=>"*"@9}, {:chr=>"Z"@10}]}}}}
  end

  def test_rule_border
    text = "----"
    @parser.border.parse(text)
    # {:border=>"----"@0}
  end

  def test_rule_line
    text1 = "----"
    @parser.line.parse(text1)
    # {:border=>"----"@0}
    text2 = "-u-|b|n"
    @parser.line.parse(text2)
    # {:line=>[{:underline=>{:text=>[{:chr=>"u"@1}]}}, {:box=>{:text=>[{:chr=>"b"@4}]}}, {:text=>[{:chr=>"n"@6}]}]}
    text3 = "\\n"
    @parser.line.parse(text3)
    # "\\n"@0
  end

  def test_rule_lines
    text1 = "^#X_Y_Z"
    @parser.lines.parse(text1)
    # [{:triangle=>"^"@0, :brackets=>"#"@1}, {:line=>[{:text=>[{:chr=>"X"@2}]},
    #  {:subscript=>{:text=>[{:chr=>"Y"@4}]}}, {:text=>[{:chr=>"Z"@6}]}]}, {:paths=>[]}]
    text2 = "^X_Y_Z+1+>2"
    @parser.lines.parse(text2)
    # [{:triangle=>"^"@0, :enclosure=>:none},
    #  {:line=>[{:text=>[{:chr=>"X"@2}]}, {:subscript=>{:text=>[{:chr=>"Y"@4}]}}, {:text=>[{:chr=>"Z"@6}]}]},
    #  {:paths=>[{:path=>"+1"@7}, {:path=>"+>2"@9}]}]
    text3 = "^----\\n\\nX_Y_Z+1+>2"
    @parser.lines.parse(text3)
    # [{:triangle=>"^"@0, :enclosure=>:none},
    #  {:border=>"----"@1},
    #  {:blankline=>"\\n\\n"@5},
    #  {:line=>[{:text=>[{:chr=>"X"@9}]}, {:subscript=>{:text=>[{:chr=>"Y"@11}]}},
    #  {:text=>[{:chr=>"Z"@13}]}]},
    #  {:paths=>[{:path=>"+1"@14}, {:path=>"+>2"@16}]}]
  end

  def test_evaluator
    text1 = "^#----\\n\\nX_Y_Z+1+>2"
    Markup.parse text1
    # {:status=>:success,
    #  :results=>
    #   {:enclosure=>:brackets,
    #    :triangle=>true,
    #    :paths=>[{:path=>"+1"@15}, {:path=>"+>2"@17}],
    #    :contents=>
    #     [{:type=>:border},
    #      {:type=>:blankline},
    #      {:type=>:text, :elements=>[{:text=>"X", :decoration=>[]},
    #      {:text=>"Y", :decoration=>[:subscript]}, {:text=>"Z", :decoration=>[]}]}]}}
    text2 = "!^#----\\n\\nX_Y_Z+1+>2"
    Markup.parse text2
    # {:status=>:error, :text=>"!^#----\\n\\nX_Y_Z+1+>2"}
  end
end
