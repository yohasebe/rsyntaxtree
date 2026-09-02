# frozen_string_literal: true

require 'parslet'

class MarkupParser < Parslet::Parser
  rule(:cr) { str('\\n') }
  rule(:eof) { any.absent? }
  rule(:border) { rule_line >> (eof | cr) }
  rule(:bborder) { double_rule_line >> (eof | cr) }
  # The rule itself, without what ends the line. A matrix ends its rows on
  # its own closing delimiter as well as on a line break, so it supplies its
  # own terminator; folding one in here would have the two consume it twice.
  rule(:rule_line) { match('[^\-]').absent? >> str('-').repeat(3).as(:border) }
  rule(:double_rule_line) { match('[^=]').absent? >> str('=').repeat(3).as(:bborder) }

  rule(:brectangle) { str('###') }
  rule(:rectangle) { str('##') }
  rule(:brackets) { str('#') }
  rule(:triangle) { str('^') }

  # Color specification: @colorname: or @#hexcode:
  rule(:color_name) { match('[a-zA-Z]').repeat(1) }
  # Three digits or six, which is what every message about colour in this
  # codebase already says. The rule used to be written as "three to six", so
  # four and five passed the parser, passed the validator (which does not look
  # at a value beginning with '#' at all), and went into the SVG — where
  # librsvg cannot read them and draws the label black, with nothing reported.
  # Six first: on a six-digit value the three-digit branch matches and then
  # the ':' is not there to be found.
  rule(:color_hex) { str('#') >> (match('[0-9a-fA-F]').repeat(6, 6) | match('[0-9a-fA-F]').repeat(3, 3)) }
  rule(:color_spec) { str('@') >> (color_hex | color_name).as(:color_value) >> str(':') }

  # Region shade: '%' marks the node so that the whole subtree it governs
  # gets a semi-transparent background plane. An optional color spec right
  # after '%' sets the shade color (reusing color_spec); '%' alone uses the
  # default shade color. A separate trailing color_spec still sets the node
  # text/line color, so '%@yellow:@blue:VP' = yellow plane + blue label.
  rule(:region) { str('%') >> color_spec.maybe.as(:region_color) }

  rule(:path) { (str('+') >> str('-').maybe >> (str('>') | str('<')).maybe >> match('\d').repeat(1)).as(:path) }
  # rule(:escaped) { str('\\') >> match('[#<>{}\\^+*_=~\|\n\-]').as(:chr) }
  rule(:escaped) { str('\\') >> match('[#<>{}\\\\^+*_=~\\|\\n\\-\\[\\]%@]').as(:chr) }
  # A straight apostrophe is set as a curly one; `\'` asks for the straight
  # one itself. It comes through as a placeholder so the substitution, which
  # runs later on the joined text, can tell the two apart.
  rule(:kept_apostrophe) { str("\\'").as(:kept_apostrophe) }
  rule(:non_escaped) { ((match('[#<>{}\\^+*_=~\|\-]') | str('\\n') | str('\\t')).absent? >> any).as(:chr) }
  rule(:text) { (kept_apostrophe | escaped | non_escaped).repeat(1).as(:text) }

  # Column separator. Every line of a label is cut at these into cells, and
  # each column is laid out at the width of its widest cell, which is what an
  # attribute-value matrix needs: attributes in one column, values in the next.
  rule(:tabstop) { str('\\t').as(:tabstop) }

  rule(:horizontal_bar) { str('--').as(:horizontal_bar) }
  rule(:arrow_both) { str('<->').as(:arrow_both) }
  rule(:arrow_to_r) { str('->').as(:arrow_to_r) }
  rule(:arrow_to_l) { str('<-').as(:arrow_to_l) }
  rule(:empty_circle) { str('{}').as(:empty_circle) }
  rule(:empty_box) { str('||').as(:empty_box) }
  rule(:hatched_circle) { str('{/}').as(:hatched_circle) }
  rule(:hatched_box) { str('|/|').as(:hatched_box) }
  rule(:circle) { str('{') >> (text | decoration).as(:circle) >> str('}') }
  rule(:box) { str('|') >> (text | decoration).as(:box) >> str('|') }

  rule(:bolditalic) { str('***') >> (text | decoration).as(:bolditalic) >> str('***') }
  rule(:bold) { str('**') >> (text | decoration).as(:bold) >> str('**') }
  rule(:italic) { str('*') >> (text | decoration).as(:italic) >> str('*') }

  rule(:bstroke) { str('*') >> shape.as(:bstroke) >> str('*') }

  rule(:overline) { str('=') >> (text | decoration).as(:overline) >> str('=') }
  rule(:underline) { str('-') >> (text | decoration).as(:underline) >> str('-') }
  rule(:linethrough) { str('~') >> (text | decoration).as(:linethrough) >> str('~') }

  rule(:small) { str('___') >> (text | decoration | shape).as(:small) >> str('___') }
  rule(:superscript) { str('__') >> (text | decoration | shape).as(:superscript) >> str('__') }
  rule(:subscript) { str('_') >> (text | decoration | shape).as(:subscript) >> str('_') }

  rule(:decoration) { (bolditalic | bold | italic | small | superscript | subscript | overline | underline | linethrough) }

  rule(:shape) { (hatched_circle | hatched_box | empty_circle | empty_box | horizontal_bar | arrow_both | arrow_to_l | arrow_to_r | circle | box) }

  # A matrix inside a label: the value of an attribute can be another
  # attribute-value matrix, which is what a feature structure of any depth
  # needs. Rows are separated by \n and cells by \t, exactly as at the top
  # level, and the group draws its own brackets. '#(' and '#)' delimit it —
  # bare brackets would be read as tree structure and bare parentheses appear
  # in labels too often to claim.
  rule(:matrix) { str('#(') >> matrix_line.repeat(1).as(:matrix) >> str('#)') }
  rule(:matrix_line) { (rule_line | double_rule_line | matrix_markup.repeat(1).as(:line)) >> (cr | str('#)').present?) }
  rule(:matrix_markup) { (matrix | tabstop | matrix_text | decoration | shape | bstroke) }
  # Text inside a matrix stops at the closing delimiter as well.
  rule(:matrix_text) { (kept_apostrophe | escaped | (str('#)').absent? >> non_escaped)).repeat(1).as(:text) }

  rule(:markup) { (matrix | tabstop | text | decoration | shape | bstroke) }

  # A label that is one whole matrix. The enclosure rules in :lines would
  # eat the '#' of '#(' before the matrix rule could see it, so a matrix
  # could only live inside a label, never be one. Trying this first is
  # safe: a label starting '#(' that contains the closing '#)' could never
  # parse before (a bare '#' is not consumable outside a matrix), so the
  # only inputs this newly reaches are ones that used to fail. A matrix
  # followed by anything but a path or the end does not match here and
  # falls through to the enclosure reading, exactly as before.
  rule(:whole_label_matrix) { matrix >> (str('+') | cr | eof).present? }

  rule(:line) { (cr.as(:extracr) | border | bborder | markup.repeat(1).as(:line) >> (cr | eof | str('+').present?)) }
  rule(:lines) { triangle.maybe.as(:triangle) >> (whole_label_matrix.as(:whole_label_matrix) | ((brectangle | rectangle | brackets).maybe.as(:enclosure) >> region.maybe.as(:region) >> color_spec.maybe.as(:color) >> line.repeat(1))) >> path.repeat(0).as(:paths) >> (cr | eof) }
  root :lines
end

module Markup
  # Stands in for an escaped apostrophe until the curly substitution has
  # run. A private-use character no label carries.
  KEPT_APOSTROPHE = "\uE000"

  @parser = MarkupParser.new

  @evaluator = Parslet::Transform.new do
    rule(chr: simple(:chr)) { chr.to_s }
    rule(kept_apostrophe: simple(:kept)) { KEPT_APOSTROPHE }
    rule(text: sequence(:text)) { { text: text.join(""), decoration: [] } }

    rule(tabstop: subtree(:empty)) {
      { text: +"", decoration: [:tabstop] }
    }

    rule(horizontal_bar: subtree(:empty)) {
      { text: +"　", decoration: [:bar] }
    }
    rule(arrow_both: subtree(:empty)) {
      { text: +"　", decoration: [:bar, :arrow_to_l, :arrow_to_r] }
    }
    rule(arrow_to_l: subtree(:empty)) {
      { text: +"　", decoration: [:bar, :arrow_to_l] }
    }
    rule(arrow_to_r: subtree(:empty)) {
      { text: +"　", decoration: [:bar, :arrow_to_r] }
    }

    rule(empty_circle: subtree(:empty)) {
      { text: +"　", decoration: [:circle] }
    }
    rule(empty_box: subtree(:empty)) {
      { text: +"　", decoration: [:box] }
    }
    rule(hatched_circle: subtree(:empty)) {
      { text: +"　", decoration: [:hatched, :circle] }
    }
    rule(hatched_box: subtree(:empty)) {
      { text: +"　", decoration: [:hatched, :box] }
    }

    rule(bolditalic: subtree(:text)) {
      text[:decoration] << :bolditalic; text
    }
    rule(bold: subtree(:text)) {
      text[:decoration] << :bold; text
    }
    rule(italic: subtree(:text)) {
      text[:decoration] << :italic; text
    }

    rule(bstroke: subtree(:box)) {
      box[:decoration] << :bstroke; box
    }
    rule(bstroke: subtree(:circle)) {
      circle[:decoration] << :bstroke; circle
    }
    rule(bstroke: subtree(:horizontal_bar)) {
      horizontal_bar[:decoration] << :bstroke; horizontal_bar
    }
    rule(bstroke: subtree(:empty_circle)) {
      empty_circle[:decoration] << :bstroke; empty_circle
    }
    rule(bstroke: subtree(:empty_box)) {
      empty_box[:decoration] << :bstroke; empty_box
    }
    rule(bstroke: subtree(:hatched_circle)) {
      hatched_circle[:decoration] << :bstroke; hatched_circle
    }
    rule(bstroke: subtree(:hatched_box)) {
      hatched_box[:decoration] << :bstroke; hatched_box
    }

    rule(overline: subtree(:text)) {
      text[:decoration] << :overline; text
    }
    rule(underline: subtree(:text)) {
      text[:decoration] << :underline; text
    }
    rule(linethrough: subtree(:text)) {
      text[:decoration] << :linethrough; text
    }
    rule(subscript: subtree(:text)) {
      text[:decoration] << :subscript; text
    }
    rule(superscript: subtree(:text)) {
      text[:decoration] << :superscript; text
    }
    rule(small: subtree(:text)) {
      text[:decoration] << :small; text
    }
    rule(box: subtree(:text)) {
      text[:decoration] << :box; text
    }
    rule(circle: subtree(:text)) {
      text[:decoration] << :circle; text
    }
    rule(border: simple(:border)) {
      { type: :border }
    }
    rule(bborder: simple(:bborder)) {
      { type: :bborder }
    }
    # A nested matrix reaches the element list as one element carrying its own
    # lines, so the measuring and drawing code can recurse into it.
    rule(matrix: subtree(:matrix)) {
      { text: +"", decoration: [:matrix], matrix: matrix }
    }
    rule(line: subtree(:line)) {
      { type: :text, elements: line }
    }
    rule(extracr: subtree(:extracr)) {
      { type: :text, elements: [{ text: +"　", decoration: [] }] }
    }
  end

  # Largest charpos anywhere in a parse-failure cause tree: the position
  # the parser actually reached before giving up.
  def deepest_charpos(cause, best = 0)
    pos = cause.respond_to?(:pos) && cause.pos ? cause.pos.charpos : 0
    best = [best, pos].max
    cause.children&.each { |child| best = deepest_charpos(child, best) }
    best
  end

  def parse(txt)
    begin
      parsed = @parser.parse(txt)
    rescue Parslet::ParseFailed => e
      # The cause is kept: the deepest node of the failure tree is where the
      # parse actually got stuck, which is what structured errors report.
      return { status: :error, text: txt, charpos: deepest_charpos(e.parse_failure_cause) }
    end

    applied = @evaluator.apply(parsed)
    # A label holding a single named part (a whole-label matrix, nothing
    # else) comes back as one hash, not a one-element array.
    applied = [applied] unless applied.is_a?(Array)

    results = { enclosure: :none, triangle: false, paths: [], contents: [], color: nil, region: false, region_color: nil }
    applied.each do |h|
      # Region shade (whole-subtree background). '%' sets it on; an optional
      # color right after '%' overrides the default shade color.
      if h[:region]
        results[:region] = true
        region_color = h[:region][:region_color]
        results[:region_color] = region_color[:color_value].to_s if region_color && region_color[:color_value]
      end
      if h[:enclosure]
        results[:enclosure] = case h[:enclosure].to_s
                              when '###'
                                :brectangle
                              when '##'
                                :rectangle
                              when '#'
                                :brackets
                              else
                                :none
                              end
      end
      results[:triangle] = h[:triangle].to_s == '^' if h[:triangle]
      results[:paths] = h[:paths] if h[:paths]
      # Handle color specification
      if h[:color] && h[:color][:color_value]
        color_value = h[:color][:color_value].to_s
        # Prepend # if it's a hex color without it (parser captures just the hex part after #)
        results[:color] = color_value
      end
      results[:contents] << h if h[:type] == :text || h[:type] == :border || h[:type] == :bborder
      # A label that is one whole matrix arrives under its own key in the
      # top-level hash; the matrix element becomes the label's only line.
      results[:contents] << { type: :text, elements: [h[:whole_label_matrix]] } if h[:whole_label_matrix]
    end
    { status: :success, results: results }
  end

  module_function :parse, :deepest_charpos
end

