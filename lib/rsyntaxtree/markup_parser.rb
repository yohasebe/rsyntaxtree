require 'parslet'

class MarkupParser < Parslet::Parser
  rule(:blankline) { str('\\n\\n').as(:blankline)}
  rule(:cr) { str('\\n')}

  rule(:escaped) { str('\\') >> (match('[*_=\|\-]')).as(:chr) }
  rule(:non_escaped) { ((match('[*_=\|\n\-]') | str('\\n')).absent? >> any).as(:chr) }
  rule(:text) { (escaped | non_escaped).repeat(1).as(:text) }

  rule(:bolditalic) { str('***') >> (text | superscript | subscript | box).as(:bolditalic) >> str('***')}
  rule(:bold) { str('**') >> (text | superscript | subscript | box).as(:bold) >> str('**')}
  rule(:italic) { str('*') >> (text | superscript | subscript | box).as(:italic) >> str('*')}

  rule(:superscript) { str('__') >> (text | box | bolditalic | bold | italic).as(:superscript) >> str('__')}
  rule(:subscript) { str('_') >> (text | box | bolditalic | bold | italic).as(:subscript) >> str('_')}
  rule(:box) { str('|') >> (text | bolditalic | bold | italic).as(:box) >> str('|')}

  rule(:markup) { (text | bolditalic | bold | italic | superscript | subscript | box) }
  rule(:border) { str('-').repeat(4).as(:border) }
  rule(:line) { ( blankline | border | (markup.repeat(1)).as(:line) >> cr | markup.repeat(1).as(:line) | cr ) }
  rule(:lines) { line.repeat(1) }
  root :lines
end

module Markup
  @parser = MarkupParser.new

  @evaluator = Parslet::Transform.new do
    rule(:chr => simple(:chr)) { chr.to_s }
    rule(:text => sequence(:text)) { {:text => text.join(""), :decoration => []} }
    rule(:bolditalic => subtree(:text)) {
      text[:decoration] << :bolditalic; text
    }
    rule(:bold => subtree(:text)) {
      text[:decoration] << :bold; text
    }
    rule(:italic => subtree(:text)) {
      text[:decoration] << :italic; text
    }
    rule(:subscript => subtree(:text)) {
      text[:decoration] << :subscript; text
    }
    rule(:superscript => subtree(:text)) {
      text[:decoration] << :superscript; text
    }
    rule(:box => subtree(:text)) {
      text[:decoration] << :box; text
    }
    rule(:border => simple(:border)) {
      {:type => :border}
    }
    rule(:blankline => simple(:blankline)) {
      {:type => :blankline}
    }
    rule(:line => subtree(:markup)) {
      {:type => :text, :elements => markup}
    }
  end

  def parse(txt)
    parsed = @parser.parse(txt)
    results = @evaluator.apply(parsed)
  end

  module_function :parse
end

# parsed = Markup.parse('\_あり\-がとう**_X_**\\n----\\n\\n__|Y|__')
