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
    attr_accessor :ink_top, :ink_bottom, :rule_name, :label_with_rule_name, :id, :parent, :type, :level, :width, :height, :content, :content_width, :text_width, :content_height, :horizontal_indent, :vertical_indent, :triangle, :enclosure, :children, :font, :fontsize, :contains_phrase, :path, :color, :raw_content, :region, :region_color

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

      @path = if /.+?\^?((?:\+-?>?<?\d+)+)\^?\z/m =~ content
                $1.sub(/\A\+/, "").split("+")
              else
                []
              end

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
        name = at && content[(at + 2)..].to_s.strip
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

      @raw_content = content.sub(/\^?(?:\+-?>?<?\d+)+\^?\z/, '')

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
    # in a path suffix (+-1, +->2) is what makes that path dashed. Swapping
    # those turned a rule into the text "---" without a word of complaint.
    # Split a label into lines with the trailing path markers detached, so
    # hyphen handling can spare the two places a run of hyphens means
    # something else: a `---` rule line of its own, and the `+-2` markers
    # at the end. Shared by swap_hyphen_markup and escape_hyphens.
    def self.hyphen_safe_lines(text)
      path = text[/\^?(?:\+-?>?<?\d+)+\^?\z/]
      body = path ? text[0...-path.length] : text
      [body.split('\n', -1), path.to_s]
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
       ->(s) { s.sub(/\A%?@(?:#[0-9a-zA-Z]+|[a-zA-Z]+)?:/, "") },
       "A color is @name: with a CSS color name, or @#rgb: / @#rrggbb: with 3 or 6 hex digits (e.g. @blue:VP, @#3af:VP)."],
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
      [:incomplete_path,
       ->(s) { s.sub(/(?<!\\)\+>?<?\z/, "") },
       "A path marker needs a number: write +1, or +>1 for the arrowhead."]
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
                         hint: "Use a CSS color name or a hex code: @blue:VP, @#3af:VP, @#33aaff:VP.",
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
    def measure_lines(lines, nested: false)
      total_width = 0
      total_height = 0
      one_bvm_given = nested
      lines.each do |content|
        content_width = 0
        case content[:type]
        when :border, :bborder
          height = @global[:single_line_height] / 2
          content[:height] = height
          total_height += height
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

            text = e[:text]
            # Handle escaped square brackets
            text = text.gsub('\\[', '[')
                      .gsub('\\]', ']')
            # Typographic apostrophe: render a straight ASCII apostrophe (U+0027)
            # as a curly apostrophe (U+2019) for smarter typography, e.g. the
            # X-bar prime in "T'". Applied before metrics so the measured glyph
            # matches the rendered one.
            text = text.gsub("'", "’")
            e[:text] = text.gsub(" ", WHITESPACE_BLOCK)
                          .gsub(">", '&#62;')
                          .gsub("<", '&#60;')

            @contains_phrase = true if text.include?(" ")
            decoration = e[:decoration]
            fontsize = decoration.include?(:small) ? @fontsize * SUBSCRIPT_CONST : @fontsize
            fontsize = decoration.include?(:subscript) || decoration.include?(:superscript) ? fontsize * SUBSCRIPT_CONST : fontsize
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
              text.gsub!("\\\\", 'i')
              text.gsub!("\\", "")
              text.gsub!(" ", "x")
              text.gsub!("%", "X")
              metrics = FontMetrics.get_metrics(text, font, fontsize, style, weight)
              width = metrics.width
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
