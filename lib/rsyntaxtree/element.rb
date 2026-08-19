# frozen_string_literal: true

#==========================
# element.rb
#==========================
#
# Aa class that represents a basic tree element, either node or leaf.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative "markup_parser"
require_relative "utils"

module RSyntaxTree
  class Element
    attr_accessor :id, :parent, :type, :level, :width, :height, :content, :content_width, :text_width, :content_height, :horizontal_indent, :vertical_indent, :triangle, :enclosure, :children, :font, :fontsize, :contains_phrase, :path, :color, :raw_content, :region, :region_color

    def initialize(id, parent, content, level, fontset, fontsize, global)
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
      @paths = results[:paths]
      @enclosure = results[:enclosure]
      @triangle = results[:triangle]
      @color = results[:color]
      @region = results[:region]
      @region_color = results[:region_color]

      @contains_phrase = false
      setup
    end

    # True when the element renders no visible label — its text consists
    # only of whitespace placeholders (from `<>`) and it carries no
    # enclosure. Such nodes act as pass-through joints: connectors run
    # continuously through them, which lets a `<>` chain push a leaf down
    # to align with deeper leaves while the line stays unbroken.
    def empty_label?
      return false if @enclosure && @enclosure != :none

      @content.all? do |c|
        c[:type] == :text &&
          c[:elements].all? { |e| e[:text].gsub(WHITESPACE_BLOCK, "").strip.empty? }
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
    def swap_hyphen_markup(text)
      path = text[/\^?(?:\+-?>?<?\d+)+\^?\z/]
      body = path ? text[0...-path.length] : text
      swapped = body.split('\n', -1).map do |line|
        /\A-{3,}\z/.match?(line) ? line : swap_hyphens(line)
      end.join('\n')
      swapped + path.to_s
    end

    def swap_hyphens(text)
      # A character no label can contain, so the two swaps cannot see each
      # other's output. Written as an escape: a literal NUL in the source
      # makes git and grep treat this file as binary.
      placeholder = "\u0000"
      text.gsub('\\-', placeholder).gsub("-", '\\-').gsub(placeholder, "-")
    end

    # Escape the hyphens that open an underline, sparing the two places a
    # run of them means something else: a `---` rule line of its own, and
    # the `+-2` path markers at the end. Same exemptions as
    # swap_hyphen_markup, for the same reason.
    def self.escape_hyphens(text)
      path = text[/\^?(?:\+-?>?<?\d+)+\^?\z/]
      body = path ? text[0...-path.length] : text
      escaped = body.split('\n', -1).map do |line|
        /\A-{3,}\z/.match?(line) ? line : line.gsub(/(?<!\\)-/, '\\-')
      end.join('\n')
      escaped + path.to_s
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
      [:angle_brackets,
       ->(s) { s.gsub(/(?<!\\)<([^<>]*[^<>\d][^<>]*)>/) { "〈#{$1}〉" } },
       "'<' and '>' mark whitespace here, not a list. Write the angle bracket characters themselves: 〈NP〉, 'hand〈SUBJ,OBJ〉'."],
      [:bare_hyphen,
       ->(s) { Element.escape_hyphens(s) },
       "A hyphen opens an underline. Escape it (e.g. f\\-structure, V\\-bar) or pass hyphen: literal."],
      [:raw_space,
       ->(s) { s.gsub(" ", WHITESPACE_BLOCK) },
       "A raw space cut this label short. Write a space inside a label as <> (e.g. 'a<>toy')."],
      [:unclosed_matrix,
       ->(s) { s + "#)" },
       "A matrix opened with '#(' is never closed with '#)'."],
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
                             hint: "Raw spaces left this label empty. Write a space inside a label as <> (e.g. 〈<>NP<>〉).",
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

      # No repair worked, so the cause is not one this knows. Still a mistake
      # in the input rather than a limit of the tool, so a caller may rewrite
      # and try again — retryable: false is for failures no rewrite can fix.
      details.merge(code: :invalid_markup,
                    hint: "Check that *, _, =, ~, |, { and #(...#) are paired, and escape a literal markup character with a backslash.",
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
          content[:elements].each do |e|
            # A nested matrix is measured by the same code one level down, and
            # reports the size of the block it will occupy in this row: its own
            # content plus the brackets drawn around it.
            if e[:decoration].include?(:matrix)
              inner = measure_lines(e[:matrix], nested: true)
              e[:matrix_width] = inner[:width]
              e[:matrix_height] = inner[:height]
              e[:width] = inner[:width] + matrix_bracket_room * 2
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
              elements_height << e[:height]
              row_width += e[:width]
              next
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
            line_height = height
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
              centre = standard_metrics.ink_above / 2.0

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
            measured = [height, line_height].max

            if one_bvm_given
              elements_height << measured
            else
              one_bvm_given = true
              elements_height << measured + @global[:box_vertical_margin]
            end

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
