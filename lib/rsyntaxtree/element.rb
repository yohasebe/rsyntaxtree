# frozen_string_literal: true

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative "markup_parser"
require_relative "utils"
require_relative "color_names"

module RSyntaxTree
  class Element
    attr_accessor :ink_top, :ink_bottom, :rule_name, :label_with_rule_name, :id, :parent, :type, :level, :width, :height, :content, :content_width, :text_width, :content_height, :horizontal_indent, :vertical_indent, :triangle, :enclosure, :children, :font, :fontsize, :contains_phrase, :path, :color, :raw_content, :region, :region_color, :inserted_joint, :route, :link_labels

    # names_a_rule says the content is a mother's label rather than a leaf's
    # text. Only a mother has a step under it for a name to sit beside, and a
    # leaf's `a\tb` is a row of two columns, so the name is read out of the one
    # and left alone in the other.
    def initialize(id, parent, content, level, fontset, fontsize, global,
                   names_a_rule = false)
      @global = global
      @type = ETYPE_LEAF
      @id = id                 # Unique element id
      @parent = parent         # Parent element id
      @children = []           # Child element ids
      @level = level           # Element level in the tree (0=top etc...)
      @width = 0               # Width of the part of the tree including itself and it governs
      @content_width = 0       # Width of the content
      @horizontal_indent = 0   # Drawing offset
      @vertical_indent = 0     # Drawing offset
      content = content.strip

      @fontset = fontset
      @fontsize = fontsize
      # In a derivation the label may carry the name of the rule that produced
      # it, written after a column break: `S/NP\t>B`. The name is taken out
      # before the label is read as markup, so it is drawn exactly as written —
      # `>` and `<` need no escaping there, and escaping them puts the backslash
      # in the figure. (This example carried one, which is the opposite of what
      # the gallery's derivations do.) The name belongs beside
      # the rule rather than beside the result, so it comes out of the label
      # here, before the label is measured, and BaseGraph draws it at the end
      # of the rule.
      if global && global[:derivation] && names_a_rule
        at = rule_name_break(content)
        # Parentheses are escaped for the label's markup, not for the name:
        # the backslash that escapes one goes, a pair of backslashes stays.
        name = at && content[(at + 2)..].to_s.strip.gsub(/(\\+)([()])/) do
          $1.size.odd? ? $1[0..-2] + $2 : $1 + $2
        end
        if name && !name.empty?
          @rule_name = name
          # Kept whole, because whether this node has daughters — and so
          # whether it names a rule at all — is not known until the tree
          # is built. StringParser puts the label back if it turns out
          # there was no step for the name to belong to.
          @label_with_rule_name = content
          content = content[0...at]
        end
      end

      # The markers are read from the label itself, after a rule name has gone,
      # so a name that ends in what looks like one is drawn as written.
      _body, path_text = Element.split_path(content)
      markers = path_text.sub(/\\n\z/, "").scan(/\+(=|-?[<>]?)(\d+)(?:"((?:\\.|[^"\\])*)")?/)
      @path = markers.map { |kind, number, _| kind + number }
      @route, @path = @path.partition { |marker| marker.start_with?("=") }
      # The text a link carries, by its number; the kind of marker it was
      # written on goes with it, for the check that only a link carries one.
      @link_labels = markers.filter_map do |kind, number, text|
        next if text.nil? || text.empty?

        [kind, number, text.gsub(/\\(.)/, '\1').gsub(WHITESPACE_BLOCK, " ")]
      end

      @raw_content = Element.split_path(content).first

      parsed = Markup.parse(prepare_markup(content))

      if parsed[:status] == :success
        results = parsed[:results]
      else
        error_text = +"Error: input text contains an invalid string"
        error_text += "\n > " + content
        raise RSTError.new(error_text, **markup_failure_details(content, parsed[:charpos]))
      end
      @content = results[:contents]
      @enclosure = results[:enclosure]
      @triangle = results[:triangle]
      @color = results[:color]
      @region = results[:region]
      @region_color = results[:region_color]
      validate_color!(@color, content)
      validate_color!(@region_color, content)
      Element.span_colors(@content).each { |c| validate_color!(c, content) }
      Element.join_colour_runs(@content)

      @contains_phrase = false
      setup
    end

    # True when the element renders no visible label — its text consists
    # only of whitespace placeholders (from `<>`) and it carries no
    # enclosure. Such nodes act as pass-through joints: connectors run
    # continuously through them, which lets a `<>` chain push a leaf down
    # to align with deeper leaves while the line stays unbroken.
    #
    # A label that is one whole feature matrix keeps its text inside the
    # matrix and leaves none of it here, and the matrix is a decoration on the
    # run rather than the element's own enclosure. Counted as empty, such a
    # node was joined as a pass-through joint and the connectors were run to
    # the middle of it — through the matrix and the rows written in it.
    def empty_label?
      return false if @enclosure && @enclosure != :none

      @content.all? do |c|
        c[:type] == :text &&
          c[:elements].all? do |e|
            !e[:decoration].to_a.include?(:matrix) &&
              e[:text].gsub(WHITESPACE_BLOCK, "").strip.empty?
          end
      end
    end

    # With hyphen: literal, the two readings of '-' trade places: a bare one is
    # a hyphen and an escaped one opens and closes an underline. Feature names
    # in HPSG and its relatives are full of hyphens — HEAD-DTR, RELIED-ON — and
    # escaping every one of them is a poor trade for a rule nobody there uses.
    # Swapping the two before parsing leaves the grammar untouched.
    # Two uses of the hyphen are structure rather than markup, and are left
    # alone: a line of nothing but hyphens is the horizontal rule, and the dash
    # in an extra connector's suffix (+-1, +->2) is what makes it one. Swapping
    # those turned a rule into the text "---" without a word of complaint.
    # Split a label into lines with the trailing path markers detached, so
    # hyphen handling can spare the two places a run of hyphens means
    # something else: a `---` rule line of its own, and the `+-2` markers
    # at the end. Shared by swap_hyphen_markup and escape_hyphens.
    def self.hyphen_safe_lines(text)
      body, path = split_path(text)
      [body.split('\n', -1), path]
    end

    # The run of path markers a label ends in: `+1`, `+>2`, `+-3`, several of
    # them, an optional `^` on either side. A marker's `+` is a marker only
    # when the backslashes before it are even in number: `x\+1` is a plus
    # sign and a digit, `x\\+1` a backslash and a marker. Detection used to
    # ignore the backslash, so a label could not contain "+1" at all — every
    # "C++11" and "2+2" was read as one end of a movement link.
    PATH_MARKERS = /(?:\+(?:=|-?>?<?)\d+(?:"(?:\\.|[^"\\])*")?)+/

    # The colours of the coloured stretches in a label's lines, nested
    # matrices included.
    def self.span_colors(lines)
      lines.flat_map do |line|
        next [] unless line[:type] == :text

        line[:elements].flat_map do |e|
          [*e[:span_colors], *(e[:matrix] ? span_colors(e[:matrix]) : [])]
        end
      end
    end

    # Runs that differ only in colour are one stretch of text, measured and
    # set as one so that kerning and the joining of a script carry across the
    # change; each part keeps its colour. Only runs with a colour are joined,
    # so a label without one is laid out as it always was.
    SET_APART = %i[box circle bar whitespace tabstop matrix].freeze

    def self.join_colour_runs(lines)
      lines.each do |line|
        next unless line[:type] == :text

        joined = []
        line[:elements].each do |e|
          join_colour_runs(e[:matrix]) if e[:matrix]
          prev = joined.last
          if prev && (prev[:parts] || prev[:color] || e[:color]) &&
             prev[:decoration] == e[:decoration] && (e[:decoration] & SET_APART).empty?
            prev[:parts] ||= [[prev[:text], prev[:color]]]
            prev[:parts] << [e[:text], e[:color]]
            prev[:text] += e[:text]
            prev[:color] = nil
          else
            joined << e
          end
        end
        line[:elements] = joined
      end
    end

    # A label's text as written. What is drawn keeps &, < and > as the SVG
    # entities the input is read into; the formats that are not SVG want the
    # characters back.
    def self.plain_text(text)
      text.gsub("&#60;", "<").gsub("&#62;", ">").gsub("&amp;", "&")
    end

    # Splits a label into what is drawn and its trailing path text, the
    # latter empty when there is none. A label that is nothing but markers
    # has no path: there would be nothing to draw them from.
    def self.split_path(text)
      i = 0
      while (i = text.index("+", i))
        tail = text[i..]
        # A line break may follow the markers, as the grammar allows one; it
        # stays with them, so the label reads back in its own order.
        if i.positive? && tail.match?(/\A#{PATH_MARKERS}\^?(?:\\n)?\z/) &&
           text[0...i][/\\*\z/].length.even?
          i -= 1 if i > 1 && text[i - 1] == "^" && text[0...(i - 1)][/\\*\z/].length.even?
          return [text[0...i], text[i..]]
        end
        i += 1
      end
      [text, ""]
    end

    def swap_hyphen_markup(text)
      lines, path = Element.hyphen_safe_lines(text)
      lines.map { |line| /\A-{3,}\z/.match?(line) ? line : swap_hyphens(line) }.join('\n') + path
    end

    def swap_hyphens(text)
      # A character no label can contain, so the two swaps cannot see each
      # other's output. Written as an escape: a literal NUL in the source
      # makes git and grep treat this file as binary.
      placeholder = "\u0000"
      text.gsub('\\-', placeholder).gsub("-", '\\-').gsub(placeholder, "-")
    end

    # Escape the hyphens that open an underline. Shares its exemptions with
    # swap_hyphen_markup through hyphen_safe_lines.
    def self.escape_hyphens(text)
      lines, path = hyphen_safe_lines(text)
      lines.map { |line| /\A-{3,}\z/.match?(line) ? line : line.gsub(/(?<!\\)-/, '\\-') }.join('\n') + path
    end

    # What the markup parser is actually handed: under hyphen: literal a
    # hyphen and its escape swap roles before parsing.
    def prepare_markup(text)
      @global[:literal_hyphen] ? swap_hyphen_markup(text) : text
    end

    # The opening of a coloured stretch, after an even run of backslashes
    # (which are literal backslashes, so the '@' is not escaped), and a line
    # or column break written \n or \t in the same way.
    SPAN_OPENER = /(?<!\\)((?:\\\\)*)@(?:#\h{6}|#\h{3}|[a-zA-Z]+)\(/
    EMPTY_SPAN = /(?<!\\)((?:\\\\)*)@(?:#\h{6}|#\h{3}|[a-zA-Z]+)\(\)/
    UNESCAPED_BREAK = /(?<!\\)(?:\\\\)*\\[nt]/

    # One candidate repair per way of getting the notation wrong, tried in
    # order. Each is a whole edit of the label, not a pattern to recognise:
    # the diagnosis below applies one and asks the parser whether the label
    # now parses, so a cause is only ever reported when its fix is known to
    # work. That keeps the list from drifting away from the grammar the way
    # a set of hand-written patterns would — the grammar is the judge.
    MARKUP_REPAIRS = [
      # A malformed color spec ('@' then a bad name or a bad hex) leaves a
      # bare '#' or '@' behind that the enclosure repair below would happily
      # blame itself for. Tried first, so a color mistake is named as one.
      [:invalid_color,
       ->(s) { s.sub(/\A%?@(?:#[0-9a-zA-Z]+|[a-zA-Z]+)?:/, "").gsub(/(?<!\\)@#(?!(?:\h{6}|\h{3})\()[0-9a-zA-Z]*\(/, "\\(") },
       "A color is @name: with a CSS color name, or @#rgb: / @#rrggbb: with 3 or 6 hex digits (e.g. @blue:VP, @#3af:VP, @red(word))."],
      [:angle_brackets,
       ->(s) { s.gsub(/(?<!\\)<([^<>]*[^<>\d][^<>]*)>/) { "⟨#{$1}⟩" } },
       "'<' and '>' mark whitespace here, not a list. Write the angle bracket characters themselves: ⟨NP⟩, 'hand⟨SUBJ,OBJ⟩'."],
      [:bare_hyphen,
       ->(s) { Element.escape_hyphens(s) },
       "A hyphen opens an underline. Escape it (e.g. f\\-structure, V\\-bar) or set the hyphen option to literal."],
      # Every other repair leaves a label it has nothing to do with exactly
      # as it was, and an unchanged label is not tried. Appending always
      # changes one, so this one asks first whether there is an unclosed
      # matrix at all: without that, a label of "^" parses once "#)" is
      # stuck on the end, and would be reported as a matrix left open.
      [:unclosed_matrix,
       ->(s) { s.scan("#(").size > s.scan("#)").size ? s + "#)" : s },
       "A matrix opened with '#(' is never closed with '#)'."],
      # A coloured stretch left open, or written inside other markup. Asked
      # before the single characters below, whose repairs would also get the
      # label through and name the wrong mistake.
      [:empty_markup,
       # Filled rather than removed: a label of nothing but the stretch would
       # be left with nothing to parse.
       ->(s) { s.gsub(EMPTY_SPAN, '\\1x') },
       "A coloured stretch @color() is empty: put what it colours inside it, or take it out."],
      # Closed where it has to end: at the next line or column break, or else
      # before the path markers at the end of the label.
      [:unclosed_markup,
       ->(s) {
         opener = s.match(SPAN_OPENER)
         break_at = opener && s.match(UNESCAPED_BREAK, opener.end(0))
         next s unless break_at && break_at.end(0) <= Element.split_path(s).first.size

         s.dup.insert(break_at.end(0) - 2, ")")
       },
       "A coloured stretch @color(...) closes within its line or cell: close it before the \\n or \\t, " \
       "and give the next its own, as in @red(a)\\t@red(b)."],
      [:unclosed_markup,
       ->(s) {
         next s unless s.match?(SPAN_OPENER)

         label, path = Element.split_path(s)
         "#{label})#{path}"
       },
       "A coloured stretch @color(...) is never closed with ')'; a ')' inside one is written \\)."],
      [:unclosed_markup,
       ->(s) { s.gsub(SPAN_OPENER, '\\1') },
       "A coloured stretch sits inside other markup: put the colour outside, as in @red(**word**)."],
      # A derivation writes the name of each step after a column break, and
      # the combinators it is written with are made of the same characters as
      # the whitespace marker. Read as an ordinary tree such a label is
      # unclosed markup, and the advice below is about spaces — the opposite of
      # what the writer needs. Asked here, before those, so that a derivation
      # written without the option on is told so.
      [:rule_name_without_derivation,
       ->(s) { s.include?('\\n') ? s : s.sub(/(?<!\\)\\t.*\z/m, "") },
       "This label names a rule after a column break, the way a derivation " \
       "does. Turn derivation on to draw it as one, or escape the break as \\\\t."],
      # Neutralising every occurrence of one character, rather than adding a
      # closing one, locates the culprit wherever it sits in the label — an
      # opener left unclosed halfway down a matrix is not fixed by appending.
      *{ "*" => "A '*' decoration (italic or bold) is never closed.",
         "|" => "A '|' box is never closed.",
         "_" => "A '_' subscript or superscript is never closed.",
         "{" => "A '{...}' circle is never closed.",
         "=" => "An '=' overline is never closed.",
         "~" => "A '~' strikethrough is never closed.",
         "#" => "A '#' enclosure is not one of #, ## or ###, or a matrix is left open.",
         "<" => "'<' and '>' mark whitespace: <> is one space, <3> is three." }
        .map { |ch, hint| [:unclosed_markup, ->(s) { s.gsub(/(?<!\\)#{Regexp.escape(ch)}/) { "\\#{ch}" } }, hint] },
      [:stray_triangle,
       ->(s) { s.sub(/\A\^+/, "^") }, "Only one '^' may prefix a label."],
      [:incomplete_marker,
       ->(s) { s.sub(/(?<!\\)\+(?:=|>?<?)\z/, "") },
       "A marker needs a number: write +1 for a link, +>1 for its arrowhead, or +=1 for a highlighted path."],
      [:incomplete_marker,
       ->(s) { s.match?(/(?<!\\)(?:\\\\)*\+-?[<>]?\d+"[^"]*\z/) ? "#{s}\"" : s },
       "A link's text needs a closing double quote: +1\"*\"."]
    ].freeze

    # Turn a Markup.parse failure into structured error attributes: a code
    # for machines, the label and the offset inside it for people, a fix
    # that has been checked to work, and whether rewriting could help.
    def markup_failure_details(label, charpos)
      details = { label: label, position: charpos }

      # Nothing left to parse: the raw spaces around it took the whole label
      # away, one of them starting the split and the next ending it.
      if label.strip.empty?
        return details.merge(code: :label_split,
                             hint: "Raw spaces left this label empty. Write a space inside a label as <> (e.g. ⟨<>NP<>⟩).",
                             retryable: true)
      end

      MARKUP_REPAIRS.each do |code, repair, hint|
        repaired = repair.call(label)
        next if repaired == label
        # Through the same preprocessing the real parse uses, or a label
        # under hyphen: literal would be judged against a different string.
        next unless Markup.parse(prepare_markup(repaired))[:status] == :success

        return details.merge(code: code, hint: hint, retryable: true)
      end

      # No single repair worked. In practice this is where two mistakes in
      # one label land — each of them one this could have named alone — so
      # it is the most fixable bucket, not the least: still retryable, with
      # a hint that admits no one cause was found rather than naming a wrong
      # one. retryable: false is for what no rewriting reaches.
      details.merge(code: :invalid_markup,
                    hint: "No single cause fits, which usually means more than one mistake in this label. Check that *, _, =, ~, |, { and #(...#) are paired, that hyphens are escaped, and that ⟨ ⟩ are the angle bracket characters.",
                    retryable: true)
    end

    # A hex color is already constrained by the grammar; a named color is
    # checked against the names librsvg can paint, because an unknown name
    # does not fail downstream — it silently comes out black.
    def validate_color!(color, content)
      return if color.nil? || color.start_with?("#")
      return if COLOR_NAMES.include?(color.downcase)

      raise RSTError.new(+"Error: input text contains an unknown color '#{color}'" \
                         "\n > #{content}",
                         code: :unknown_color,
                         label: content,
                         hint: "Use a CSS color name or a hex code: @blue:VP, @#3af:VP, @#33aaff:VP, or @blue(word) " \
                               "for part of a label. Write \\@ for an @ meant as a character.",
                         retryable: true)
    end

    def setup
      layout = measure_lines(@content)
      @text_width = layout[:width]
      @content_width = layout[:width] + label_enclosure_room * 2
      @content_height = layout[:height]
    end

    # Room on each side of a label for its own bracket or rectangle. It is part
    # of the width the tree lays the node out at, so that whatever attaches to
    # the node — a connector, a movement arrow, the neighbour beside it —
    # meets the line actually drawn around it. A matrix nested in the label
    # keeps the same room, so the outermost pair of brackets in a feature
    # structure stands as far from its contents as every pair within.
    def label_enclosure_room
      return 0 unless [:brackets, :rectangle, :brectangle].include?(@enclosure)

      @global[:width_half_x] * MATRIX_BRACKET_ROOM
    end

    # Measures a list of label lines, filling in the width and height of every
    # element and aligning the columns that \t marks. A nested matrix runs
    # through here again, which is what lets a feature structure hold another.
    # `nested` is set for a matrix inside a label. The first row of a label
    # carries an extra margin that holds the text clear of the connector above
    # it; a nested block sits inside that margin already, so counting it again
    # would leave a bracket half a line taller than the rows it encloses.
    # A run's text as it is set: escaped square brackets as themselves, and a
    # straight ASCII apostrophe (U+0027) as a curly one (U+2019) for smarter
    # typography, e.g. the X-bar prime in "T'". Applied before metrics so the
    # measured glyph matches the rendered one.
    def typeset(text)
      text.gsub('\\[', '[').gsub('\\]', ']').gsub("'", "’").gsub(Markup::KEPT_APOSTROPHE, "'")
    end

    # A run's text as it is measured.
    def measurable(text)
      text.gsub("\\\\", 'i').gsub("\\", "").gsub(" ", "x").gsub("%", "X")
    end

    # A run's text as the drawing keeps it.
    def stored(text)
      text.gsub(" ", WHITESPACE_BLOCK).gsub(">", '&#62;').gsub("<", '&#60;')
    end

    def measure_lines(lines, nested: false)
      total_width = 0
      total_height = 0
      one_bvm_given = nested
      prev_text = nil
      lines.each do |content|
        content_width = 0
        case content[:type]
        when :border, :bborder
          height = @global[:single_line_height] / 2
          content[:height] = height
          total_height += height
          prev_text = nil
        when :text
          row_width = 0
          elements_height = []
          # A line of nothing but shapes is spaced by the shapes themselves, so
          # a grid of boxes closes up instead of showing a seam between its
          # rows. A shape sharing a line with text cannot be: the line keeps the
          # text's rhythm, and a box is nearly as tall as a line, so two of them
          # on consecutive rows would come out edge to edge.
          row_holds_text = content[:elements].any? do |e|
            (e[:decoration] & [:box, :circle, :bar]).empty? && !e[:text].to_s.strip.empty?
          end
          # True until something is drawn in the current column. A tabstop
          # opens the next one, so a block that starts a column is at the
          # start of a cell however many columns came before it.
          cell_start = true
          content[:elements].each do |e|
            # A nested matrix is measured by the same code one level down, and
            # reports the size of the block it will occupy in this row: its own
            # content plus the brackets drawn around it.
            if e[:decoration].include?(:matrix)
              inner = measure_lines(e[:matrix], nested: true)
              e[:matrix_width] = inner[:width]
              e[:matrix_height] = inner[:height]
              # A block that opens a cell needs nothing in front of it: the
              # column it starts is already held clear. One that follows
              # something in the same cell — the tag on a shared value, as in
              # AGR |1| [ ... ] — was drawn with its bracket on the ink before
              # it, because a run is spaced for the glyph that comes next and
              # a bracket is not a glyph.
              # As much room in front of the bracket as the bracket keeps
              # inside it, so the two sides of it look alike. Half as much
              # left it looking crowded from the outside.
              e[:matrix_lead] = cell_start ? 0 : matrix_bracket_room
              cell_start = false
              e[:width] = inner[:width] + matrix_bracket_room * 2 + e[:matrix_lead]
              # Two separate allowances. The block is padded inside its own
              # brackets, above and below, and that padding is part of the row.
              # The gap that keeps the block clear of the rows either side is
              # not: it widens the space the row is entered on, so the bracket
              # is not simply drawn over the line before it.
              e[:height] = inner[:height] + matrix_vertical_room * 2
              # Twice the padding: the bracket is drawn that far above the
              # baseline of its first row, so the first helping only pays for
              # the padding and the second is what actually separates the
              # bracket from the descenders of the line above it.
              content[:top_room] = matrix_vertical_room * 2
              elements_height << with_first_row_margin(e[:height], one_bvm_given)
              one_bvm_given = true
              row_width += e[:width]
              next
            end

            # A tabstop opens the next column; anything else puts ink in the
            # one being filled.
            if e[:decoration].to_a.include?(:tabstop)
              cell_start = true
            elsif !e[:text].to_s.empty?
              cell_start = false
            end

            text = typeset(e[:text])
            painted = text.gsub("\\\\", "\\")
            e[:text] = stored(text)
            typed_parts = e[:parts]&.map { |part, _| typeset(part) }
            e[:parts]&.each_with_index { |part, i| part[0] = stored(typed_parts[i]) }

            @contains_phrase = true if text.include?(" ")
            decoration = e[:decoration]
            # The size the run is drawn at: small, superscript and subscript
            # each set it at SUBSCRIPT_CONST once, nested or not.
            fontsize = (decoration & %i[small subscript superscript]).any? ? @fontsize * SUBSCRIPT_CONST : @fontsize
            style    = decoration.include?(:italic) || decoration.include?(:bolditalic) ? :italic : :normal
            weight   = decoration.include?(:bold) || decoration.include?(:bolditalic) ? :bold : :normal
            # Bold/italic are expressed through Pango's style/weight parameters,
            # so a single family list is measured for every decoration.
            font = @fontset[:family]

            standard_metrics = FontMetrics.get_metrics('X', font, fontsize, :normal, :normal)

            height = standard_metrics.height
            # The rhythm a row advances by belongs to the label, not to the size
            # a run inside it happens to be set at. Taken from the run, a label
            # that is nothing but a subscript measured a subscript tall and came
            # out shorter than the text drawn in it, so its daughters were
            # placed up into it.
            line_height = @global[:single_x_metrics].height
            if /\A[<>]+\z/ =~ text
              width = standard_metrics.width * text.size / 2
            elsif text.contains_emoji?
              segments = text.split_by_emoji
              width = 0
              segments.each do |seg|
                ch = if /\s/ =~ seg[:char]
                       't'
                     else
                       seg[:char]
                     end
                # Emoji segments are measured with the same family list;
                # fontconfig/coretext falls back to an emoji font.
                metrics = FontMetrics.get_metrics(ch, font, fontsize, style, weight)
                width += metrics.width
              end
            else
              text = measurable(text)
              metrics = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              width = metrics.width
              # A renderer may set each colour of a stretch on its own and
              # drop the kerning between them, so the stretch has room for
              # its parts set apart as well as together.
              if typed_parts
                apart = typed_parts.sum { |t| FontMetrics.get_metrics(measurable(t), font, fontsize, style, weight).width }
                width = [width, apart].max
              end
            end

            if e[:decoration].include?(:box) || e[:decoration].include?(:circle) || e[:decoration].include?(:bar)
              # One size and one height for every enclosure in a figure, so a
              # hatched circle, an empty box and a lettered tag line up and
              # share a diameter. The line's rhythm used to set the size, which
              # left a box standing a head taller than the numeral inside;
              # centring each shape on its own glyph instead made the box
              # around 's' sit lower than the one around 'G'.
              #
              # The shape is centred on a capital — the half-way point of the
              # letters it will usually hold — and drawn at ENCLOSURE_SIZE,
              # which is wide enough that a descender still clears the bottom.
              # Centring on the whole cap-to-descender band instead would sit
              # the shape low around the digits and capitals that fill most
              # tags, since those never reach below the baseline. It grows past
              # ENCLOSURE_SIZE only for content that will not fit.
              band = FontMetrics.get_metrics("Xg", font, fontsize, :normal, :normal)
              descender = band.ink_height - band.ink_above
              centre = FontMetrics.visual_centre(font, fontsize)

              ink = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              ink_height = ink.ink_height.to_f
              # Deep enough for a descender, so the one letter in a hundred that
              # has one does not get a taller box than its neighbours.
              half = [fontsize * ENCLOSURE_SIZE / 2.0, centre + descender].max

              if ink_height.positive?
                reach = [ink.ink_above - centre, centre - (ink.ink_above - ink_height)].max
                half = reach + fontsize * ENCLOSURE_PADDING if reach > half
              end

              e[:enc_height] = half * 2
              e[:enc_above] = centre + half

              height = if row_holds_text
                         [height, e[:enc_height] + fontsize * ENCLOSURE_PADDING * 2].max
                       else
                         e[:enc_height]
                       end

              e[:content_width] = width
              width += if e[:text].size == 1
                        [e[:enc_height] - width, 0].max
                      else
                        @global[:width_half_x]
                      end
            end

            if e[:decoration].include?(:whitespace)
              width = @global[:width_half_x] / 2 * e[:text].size / 4
              e[:text] = ""
            end

            # How far the run's ink reaches above and below the line's
            # baseline, where it is drawn: a shape by its outline, text by its
            # glyphs, both moved with a run set off the baseline.
            shift = Element.baseline_shift(decoration, @global, @fontsize)
            stroke = (decoration.include?(:bstroke) ? @global[:stroke_bold] : @global[:stroke_normal]) / 2.0
            if decoration.include?(:bar)
              # A bar is a stroke across the middle of the shape's height,
              # with its arrowheads reaching a quarter of its length about it.
              mid = e[:enc_above] - (e[:enc_height] / 2.0)
              reach = (decoration & %i[arrow_to_l arrow_to_r]).any? ? width / 8.0 : 0.0
              e[:ink_up] = mid + reach + stroke - shift
              e[:ink_down] = -mid + reach + stroke + shift
            elsif (decoration & %i[box circle]).any?
              e[:ink_up] = e[:enc_above] + stroke - shift
              e[:ink_down] = e[:enc_height] - e[:enc_above] + stroke + shift
            elsif !(decoration & %i[whitespace tabstop]).any? && !painted.strip.empty?
              # The glyphs as they are painted, escapes and all, at the size
              # they are drawn at.
              drawn = fontsize
              ink = FontMetrics.get_metrics(painted, font, drawn, style, weight)
              if ink.ink_height.positive?
                up = ink.ink_above
                down = ink.ink_height - ink.ink_above
                # An overline is drawn at the top of the font's line, an
                # underline a little under the baseline.
                up = [up, ink.ascent].max if decoration.include?(:overline)
                down = [down, drawn * 0.15].max if decoration.include?(:underline)
                e[:ink_up] = up - shift
                e[:ink_down] = down + shift
              end
            end

            e[:height] = height

            # What the label measures is not what its rows advance by. A line
            # of nothing but shapes advances by the shapes, so a grid closes
            # up, but it still measures a full line: the tree places a level by
            # the height of the nodes above it, so a node measured short of the
            # rhythm pulls its own children up and off the row its cousins sit
            # on.
            elements_height << with_first_row_margin([height, line_height].max, one_bvm_given)
            one_bvm_given = true

            e[:width] = width
            row_width += width
          end

          content[:height] = elements_height.max
          total_height += elements_height.max + content[:top_room].to_f
          # The rows of a nested matrix keep their rhythm: the matrix is drawn
          # row by row at it, and is a block of its own inside the label.
          if !nested && prev_text && text_row?(prev_text) && text_row?(content)
            content[:advance] = line_advance(prev_text, content)
            total_height += content[:advance] - prev_text[:elements].map { |x| x[:height] }.max
          end
          prev_text = content
          content_width += row_width
        end
        total_width = content_width if total_width < content_width
      end
      { width: align_columns(lines, total_width), height: total_height }
    end

    def add_child(child_id)
      @children << child_id
    end

    # Horizontal room a nested matrix needs on each side for its bracket and
    # the air around it.
    def matrix_bracket_room
      @global[:width_half_x] * MATRIX_BRACKET_ROOM
    end

    # Where the break that names the rule is, or nil if the label does not name
    # one. It is the break at the top level of the label: a feature matrix is
    # written with breaks of its own and those belong to its columns, so a step
    # whose category is a matrix can still name the rule that produced it.
    #
    # Exactly one, and no line break outside a matrix: a rule has one name, and
    # a label written over several lines is a matrix rather than a step. A
    # break the writer escaped is theirs and is not a break here.
    def rule_name_break(content)
      depth = 0
      breaks = []
      lined = false
      index = 0
      while index < content.length
        case content[index, 2]
        when '\\t' then breaks << index if depth.zero?
        when '\\n' then lined = true if depth.zero?
        when "#(" then depth += 1
        when "#)" then depth -= 1
        else
          # A backslash takes the character after it, whatever that character
          # is. Only the two breaks above are read here; every other escape is
          # the notation's, and `\#` is a hash that opens no matrix — counted as
          # one it left the depth wrong and the break that names the rule was
          # looked for in the wrong place.
          index += content[index] == "\\" ? 2 : 1
          next
        end
        index += 2
      end
      breaks.first if !lined && breaks.size == 1
    end

    # The first row of a label carries a margin above it that holds the text
    # clear of the connector coming down to the node. Every row is entered
    # through here so that the one holding a feature matrix is given it too: it
    # used to be measured without, and a matrix node came out shorter than the
    # rows drawn in it, which sat its daughters up inside the matrix.
    # How far one row of text is set below the row before it. A connector
    # stops vmargin short of a label's ink, and where that clearance is the
    # smaller of the two, the rows are set the same distance apart, so that a
    # label wrapped over lines reads as one block with its line and not as
    # rows hanging loose under a tight joint. Never wider than the usual
    # rhythm, and never closer than LINE_GAP_FLOOR of the type, where a tiny
    # vmargin would have the rows touch.
    LINE_GAP_FLOOR = 0.25

    #
    # The rows are set by the font's band, as the connectors are; but where
    # what is actually written reaches further — a box, a superscript, an
    # accent, an emoji — the inks are still kept the floor apart.
    def line_advance(above, below)
      rhythm = above[:elements].map { |x| x[:height] }.max
      floor = @fontsize * LINE_GAP_FLOOR
      gap = [@global[:single_x_metrics].height * @global[:vmargin].to_f, floor].max
      by_band = @global[:descender] * type_scale(above) + gap + @global[:cap_height] * type_scale(below)
      by_ink = above[:elements].filter_map { |x| x[:ink_down] }.max.to_f + floor +
               below[:elements].filter_map { |x| x[:ink_up] }.max.to_f
      [[by_band, by_ink].max, rhythm].min
    end

    # How far a run is drawn below its line's baseline (negative: above). A
    # small, superscript or subscript run is set off the baseline; the
    # drawing places it by this, and the spacing of rows reckons with it.
    def self.baseline_shift(decoration, global, fontsize)
      h = global[:single_x_metrics].height
      if decoration.include?(:small)
        -((h - (h * SUBSCRIPT_CONST)) / 4) + (fontsize / 16.0)
      elsif decoration.include?(:superscript)
        -(h / 4) + (fontsize / 32.0)
      elsif decoration.include?(:subscript)
        fontsize / 8.0
      else
        0.0
      end
    end

    # How large the type of a line is against the label's: smaller when every
    # run with ink in it is set small, as a note in ___ is.
    def type_scale(line)
      inked = line[:elements].reject { |x| x[:text].to_s.gsub(WHITESPACE_BLOCK, "").strip.empty? }
      return 1.0 if inked.empty?

      inked.map { |x| (x[:decoration] & %i[small subscript superscript]).empty? ? 1.0 : SUBSCRIPT_CONST }.max
    end

    # A row of text: no nested matrix, and some run that is not a shape. A
    # row of nothing but shapes keeps the spacing that closes a grid up.
    def text_row?(line)
      return false if line[:top_room] || line[:elements].any? { |x| x[:decoration].include?(:matrix) }

      line[:elements].any? do |x|
        (x[:decoration] & %i[box circle bar whitespace tabstop]).empty? && !x[:text].to_s.gsub(WHITESPACE_BLOCK, "").strip.empty?
      end
    end

    def with_first_row_margin(height, already_given)
      already_given ? height : height + @global[:box_vertical_margin]
    end

    # Vertical room a nested matrix keeps between itself and the rows above and
    # below it.
    def matrix_vertical_room
      @global[:single_x_metrics].height * MATRIX_VERTICAL_ROOM
    end

    private

    # Lines cut at \t are laid out in columns: every column is as wide as its
    # widest cell, so attributes line up down the left and their values down
    # the right, which is what an attribute-value matrix is. The separator
    # element carries the padding that takes its cell out to the column width,
    # and the widest line decides the label's width.
    #
    # Returns the label width, unchanged when no line has a separator.
    def align_columns(lines, fallback_width)
      rows = lines.select { |c| c[:type] == :text }
                  .map { |c| split_into_cells(c[:elements]) }
      return fallback_width unless rows.any? { |cells| cells.size > 1 }

      columns = rows.map(&:size).max
      widths = Array.new(columns) do |i|
        rows.filter_map { |cells| cells[i]&.sum { |e| e[:width] } }.max || 0
      end
      gutter = @global[:width_half_x]

      rows.each do |cells|
        cells.each_with_index do |cell, i|
          separator = cell.find { |e| e[:decoration].include?(:tabstop) }
          next unless separator

          used = cell.sum { |e| e[:width] }
          separator[:width] = widths[i] - used + gutter
        end
      end

      widths.sum + gutter * (columns - 1)
    end

    # Each cell keeps the separator that closes it, so the padding has
    # something to sit on.
    def split_into_cells(elements)
      cells = [[]]
      elements.each do |e|
        cells.last << e
        cells << [] if e[:decoration].include?(:tabstop)
      end
      cells.pop if cells.last.empty?
      cells
    end
  end
end
