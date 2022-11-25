require 'parslet'

class MarkupParser < Parslet::Parser
  rule(:cr) { str('\\n')}
  rule(:eof) { any.absent? }
  rule(:border) { match('[^\-]').absent? >> str('-').repeat(3).as(:border) >> (eof | cr) }
  rule(:bborder) { match('[^=]').absent? >> str('=').repeat(3).as(:bborder) >> (eof | cr) }

  rule(:brectangle) { str('###') }
  rule(:rectangle) { str('##') }
  rule(:brackets) { str('#') }
  rule(:triangle) { str('^') }

  rule(:path) { (str('+') >> str('>').maybe >> match('\d').repeat(1)).as(:path) }
  rule(:escaped) { str('\\') >> (match('[#<>{}\\^+*_=~\|\n\-]')).as(:chr) }
  rule(:non_escaped) { ((match('[#<>{}\\^+*_=~\|\-]') | str('\\n')).absent? >> any).as(:chr) }
  rule(:text) { (escaped | non_escaped).repeat(1).as(:text) }

  rule(:horizontal_bar) { str('--').as(:horizontal_bar) }
  rule(:arrow_both) { str('<->').as(:arrow_both) }
  rule(:arrow_to_r) { str('->').as(:arrow_to_r) }
  rule(:arrow_to_l) { str('<-').as(:arrow_to_l) }
  rule(:empty_circle) { str('{}').as(:empty_circle) }
  rule(:empty_box) { str('||').as(:empty_box) }
  rule(:hatched_circle) { str('{/}').as(:hatched_circle) }
  rule(:hatched_box) { str('|/|').as(:hatched_box) }
  rule(:circle) { str('{') >> (text|decoration).as(:circle) >> str('}')}
  rule(:box) { str('|') >> (text|decoration).as(:box) >> str('|')}

  rule(:bolditalic) { str('***') >> (text|decoration).as(:bolditalic) >> str('***')}
  rule(:bold) { str('**') >> (text|decoration).as(:bold) >> str('**')}
  rule(:italic) { str('*') >> (text|decoration).as(:italic) >> str('*')}

  rule(:bstroke) { str('*') >> shape.as(:bstroke) >> str('*')}

  rule(:overline) { str('=') >> (text|decoration).as(:overline) >> str('=')}
  rule(:underline) { str('-') >> (text|decoration).as(:underline) >> str('-')}
  rule(:linethrough) { str('~') >> (text|decoration).as(:linethrough) >> str('~')}

  rule(:small) { str('___') >> (text|decoration|shape).as(:small) >> str('___')}
  rule(:superscript) { str('__') >> (text|decoration|shape).as(:superscript) >> str('__')}
  rule(:subscript) { str('_') >> (text|decoration|shape).as(:subscript) >> str('_')}

  rule(:decoration) {(bolditalic | bold | italic | small | superscript | subscript |
                      overline | underline | linethrough) }

  rule(:shape) {(hatched_circle | hatched_box | empty_circle | empty_box |
                 horizontal_bar | arrow_both | arrow_to_l | arrow_to_r |
                 circle | box ) }

  rule(:markup) {(text | decoration | shape | bstroke)}

  rule(:line) { ( cr.as(:extracr) | border | bborder | markup.repeat(1).as(:line) >> (cr | eof | str('+').present?))}
  rule(:lines) { triangle.maybe.as(:triangle) >>
                 (brectangle | rectangle | brackets).maybe.as(:enclosure) >>
                 line.repeat(1) >>
                 path.repeat(0).as(:paths) >> (cr | eof) }
  root :lines
end

module Markup
  @parser = MarkupParser.new

  @evaluator = Parslet::Transform.new do
    rule(:chr => simple(:chr)) { chr.to_s }
    rule(:text => sequence(:text)) {{:text => text.join(""), :decoration => []} }

    rule(:horizontal_bar => subtree(:empty)) {
      {:text => "　", :decoration => [:bar]}
    }
    rule(:arrow_both => subtree(:empty)) {
      {:text => "　", :decoration => [:bar, :arrow_to_l, :arrow_to_r]}
    }
    rule(:arrow_to_l => subtree(:empty)) {
      {:text => "　", :decoration => [:bar, :arrow_to_l]}
    }
    rule(:arrow_to_r => subtree(:empty)) {
      {:text => "　", :decoration => [:bar, :arrow_to_r]}
    }

    rule(:empty_circle => subtree(:empty)) {
      {:text => "　", :decoration => [:circle]}
    }
    rule(:empty_box => subtree(:empty)) {
      {:text => "　", :decoration => [:box]}
    }
    rule(:hatched_circle => subtree(:empty)) {
      {:text => "　", :decoration => [:hatched, :circle]}
    }
    rule(:hatched_box => subtree(:empty)) {
      {:text => "　", :decoration => [:hatched, :box]}
    }

    rule(:bolditalic => subtree(:text)) {
      text[:decoration] << :bolditalic; text
    }
    rule(:bold => subtree(:text)) {
      text[:decoration] << :bold; text
    }
    rule(:italic => subtree(:text)) {
      text[:decoration] << :italic; text
    }

    rule(:bstroke => subtree(:box)) {
      box[:decoration] << :bstroke; box
    }
    rule(:bstroke => subtree(:circle)) {
      circle[:decoration] << :bstroke; circle
    }
    rule(:bstroke => subtree(:horizontal_bar)) {
      horizontal_bar[:decoration] << :bstroke; horizontal_bar
    }
    rule(:bstroke => subtree(:empty_circle)) {
      empty_circle[:decoration] << :bstroke; empty_circle
    }
    rule(:bstroke => subtree(:empty_box)) {
      empty_box[:decoration] << :bstroke; empty_box
    }
    rule(:bstroke => subtree(:hatched_circle)) {
      hatched_circle[:decoration] << :bstroke; hatched_circle
    }
    rule(:bstroke => subtree(:hatched_box)) {
      hatched_box[:decoration] << :bstroke; hatched_box
    }

    rule(:overline => subtree(:text)) {
      text[:decoration] << :overline; text
    }
    rule(:underline => subtree(:text)) {
      text[:decoration] << :underline; text
    }
    rule(:linethrough => subtree(:text)) {
      text[:decoration] << :linethrough; text
    }
    rule(:subscript => subtree(:text)) {
      text[:decoration] << :subscript; text
    }
    rule(:superscript => subtree(:text)) {
      text[:decoration] << :superscript; text
    }
    rule(:small => subtree(:text)) {
      text[:decoration] << :small; text
    }
    rule(:box => subtree(:text)) {
      text[:decoration] << :box; text
    }
    rule(:circle => subtree(:text)) {
      text[:decoration] << :circle; text
    }
    rule(:math => subtree(:text)) {
      text[:decoration] << :math; text
    }
    rule(:border => simple(:border)) {
      {:type => :border}
    }
    rule(:bborder => simple(:bborder)) {
      {:type => :bborder}
    }
    rule(:line => subtree(:line)) {
      {:type => :text, :elements => line }
    }
    rule(:extracr => subtree(:extracr)) {
      {:type => :text, :elements=>[{:text=>"　", :decoration=>[]}]}
    }

  end

  def parse(txt)
    begin
      parsed = @parser.parse(txt)
    rescue Parslet::ParseFailed
      # puts e.parse_failure_cause.ascii_tree
      return {:status => :error, :text => txt}
    end

    applied = @evaluator.apply(parsed)

    results = {:enclosure => :none, :triangle => false, :paths => [], :contents => []}
    applied.each do |h|
      if h[:enclosure]
        if h[:enclosure].to_s == '###'
          results[:enclosure] = :brectangle
        elsif h[:enclosure].to_s == '##'
          results[:enclosure] = :rectangle
        elsif h[:enclosure].to_s == '#'
          results[:enclosure] = :brackets
        else
          results[:enclosure] = :none
        end
      end
      if h[:triangle]
        results[:triangle] = h[:triangle].to_s == '^' ? true : false
      end
      if h[:paths]
        results[:paths] = h[:paths]
      end
      if h[:type] == :text || h[:type] == :border || h[:type] == :bborder
        results[:contents] << h
      end
    end
    result = {:status => :success, :results  => results}
    result
  end

  module_function :parse
end

# pp results = Markup.parse('^#\_\#\+あり\-がとう**_X_**\\n----\\n933\\n__|Y|__+>3+2+1343+>5464')
