# frozen_string_literal: true

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
# A box or circle is drawn at this size — a fraction of the font size —
# whatever it encloses, so that hatched, empty and lettered shapes in one
# figure share a diameter. It only grows for content that would not fit:
# see ENCLOSURE_PADDING and Element#setup.
ENCLOSURE_SIZE = 1.3
# Breathing room kept between the marks and a shape that had to grow past
# ENCLOSURE_SIZE, as a fraction of the font size.
ENCLOSURE_PADDING = 0.12
# Room on each side of a matrix nested in a label, as a multiple of half an
# 'X'. It sets the distance between a matrix and its own brackets, and so also
# the distance between the brackets of adjacent or nested matrices — the
# closing brackets of a deep feature path stack up otherwise.
MATRIX_BRACKET_ROOM = 2.5
# Room above and below a matrix nested in a label, as a fraction of the line
# height. Without it a bracketed value sits hard against the rows either side
# of it, since the rows are spaced for text rather than for a block.
MATRIX_VERTICAL_ROOM = 0.25
FONT_SCALING = 2
WHITESPACE_BLOCK = "￭"

# Every format the library can produce, and the file extension each one
# writes. The CLI builds its --format validation, help text, and output
# filename from these, so a new format is added here and nowhere else.
FORMATS = %w[png pdf svg json tikz].freeze
FORMAT_EXTENSIONS = {
  "png" => "png",
  "pdf" => "pdf",
  "svg" => "svg",
  "json" => "json",
  "tikz" => "tex" # forest code, to be included in a LaTeX document
}.freeze

# The values an option may carry, checked as given — before normalization —
# so an alias the normalization already accepts keeps passing, and anything
# else fails loudly instead of being silently read as something else. The
# CLI has always rejected these; the library did not, which left the web UI
# and any other programmatic caller unguarded. Booleans stay lenient on
# purpose (see switched_on?); unknown keys are not rejected, because callers
# pass their own extra parameters through.
OPTION_VALUES = {
  # lsif is the name the JSON format wore from 1.11.0 to 2.0.0, accepted as
  # an alias until 3.0. It collided with a code-intelligence format of the
  # same initials, and claimed an interchange nobody else had implemented.
  format: FORMATS + ["lsif"],
  leafstyle: %w[auto triangle bar nothing],
  fontstyle: ["sans", "serif", "cjk", "mono", "noto-sans", "noto-serif", "noto-sans-mono", "cjk zenhei"],
  color: %w[modern traditional gray grey off none on true false],
  tidy: %w[off symmetric low medium high on compact true false],
  direction: %w[ttb ltr btt],
  hyphen: %w[markup literal],
  derivation: %w[on off true false yes no 0 1 none]
}.freeze

NUMERIC_RANGES = {
  fontsize: 6..26,
  linewidth: 0.5..3.0,
  vheight: 0.5..5.0,
  hspacing: 0.5..3.0,
  shear: -45..45,
  vmargin: 0.1..1.0
}.freeze

# Options 2.0 removed, and what to say instead. An unknown key is passed over
# in silence, because a caller may hand its own parameters through — which is
# right for a key this library never had, and wrong for one it used to obey.
# A program that still asks for symmetrize would have been given the layout it
# asked for in 1.x and a different one here, with nothing said. Named here,
# the ask is refused the way `-f jpg` and `leafstyle: none` are.
REMOVED_OPTIONS = {
  symmetrize: 'tidy: "symmetric"',
  tidy_spacing: "hspacing",
  tidy_nest: 'tidy: "high"'
}.freeze

DEFAULT_OPTS = {
  format: "png",
  leafstyle: "auto",
  fontstyle: "sans",
  fontsize: 16,
  linewidth: 1,
  vheight: 2.0,
  color: "modern",
  transparent: "off",
  polyline: "off",
  hide_default_connectors: "off",
  mirror: "off",
  tidy: "off",
  hspacing: 1.0,
  direction: "ttb",
  hyphen: "markup",
  derivation: "off",
  shear: 0,
  shear_plane: "on",
  # 0.4 keeps the level pitch the historical drawing had, and replaces its
  # unequal air — a little more below every label than above it, an
  # unadjusted leftover of measuring from the layout box — with the same
  # clearance on both sides of the ink.
  vmargin: 0.4
}.freeze

# A parse or generation failure. `message` is the human-readable text the
# CLI and the web UI display and must stay stable; the structured attributes
# ride alongside for machine callers (`--validate`, an MCP server, a repair
# loop). `code` is a Symbol; `label`/`position` locate the failure inside
# the offending label when one is known; `hint` is a one-line fix; and
# `retryable` tells a caller whether applying the hint could plausibly fix
# the input (false means retrying would be guessing).
class RSTError < StandardError
  attr_reader :code, :label, :position, :hint, :retryable

  def initialize(msg = "Error: something unexpected occurred", code: :invalid, label: nil, position: nil, hint: nil, retryable: false)
    # Non-destructive: every file here carries frozen_string_literal, so
    # mutating the message in place turned a raise with a plain literal into
    # a FrozenError from inside the error class itself.
    @code = code
    @label = label
    @position = position
    @hint = hint
    @retryable = retryable
    super(msg.gsub(WHITESPACE_BLOCK, "<>"))
  end

  # Every code an error from this library can carry. Consumers dispatch on
  # these — a translation keyed by code, a harness counting what kinds of
  # mistake occur — and both need to know the whole set, not only the codes
  # they have happened to see: a kind of mistake nobody made is not the same
  # as a kind that cannot happen. Until this list existed the set was only
  # discoverable by reading five files and a repair table.
  #
  # Written out rather than computed, because it is a contract and a contract
  # should be readable at a glance and visible in a diff. A test keeps it
  # honest by finding the codes the library actually raises and comparing.
  #
  # The list grows and does not churn: a code once published is not renamed
  # or removed, so a consumer keyed by code — a translation table, a tally of
  # what kinds of mistake a writer makes — only ever has entries to add.
  #
  # Eight are named by the repair table, which diagnoses a label by rewriting
  # it and asking the parser whether the rewrite reads: angle_brackets,
  # bare_hyphen, incomplete_path, invalid_color, rule_name_without_derivation,
  # stray_triangle, unclosed_markup, unclosed_matrix. invalid_markup is where
  # a label lands whose mistake no single rewrite fits, which in practice
  # means more than one. unknown_color and label_split are mistakes inside a
  # label too, found before the repair table is reached.
  CODES = %i[
    angle_brackets
    bare_hyphen
    empty_brackets
    empty_input
    incomplete_path
    internal_error
    invalid_color
    invalid_markup
    invalid_option
    label_split
    path_multiple_ends
    path_single_end
    result_too_big
    rule_name_without_derivation
    stray_triangle
    unbalanced_brackets
    unclosed_markup
    unclosed_matrix
    unknown_color
  ].freeze

  # Where the notation is written down. A hint repairs the mistake in front of
  # it and says nothing about the rest, which is enough for a reader who knows
  # the notation and not enough for one who was guessing at it. Given once, at
  # the top, rather than repeated on every error.
  REFERENCE = "rsyntaxtree --notation, or https://yohasebe.github.io/rsyntaxtree/llms-full.txt"

  # One error as the hash the JSON diagnosis carries; to_h wraps a single
  # one and diagnose collects many.
  def error_entry
    { "code" => code.to_s,
      "message" => message,
      "label" => label,
      "position" => position,
      "hint" => hint,
      "retryable" => retryable }.compact
  end

  def to_h
    { "ok" => false,
      "errors" => [error_entry],
      "reference" => REFERENCE }
  end
end

require_relative 'rsyntaxtree/utils'
require_relative 'rsyntaxtree/element'
require_relative 'rsyntaxtree/elementlist'
require_relative 'rsyntaxtree/svg_graph'
require_relative 'rsyntaxtree/json_graph'
require_relative 'rsyntaxtree/tikz_generator'
require_relative 'rsyntaxtree/version'
require_relative 'rsyntaxtree/string_parser'
require_relative 'rsyntaxtree/format_converter'

require 'cgi'
require 'rsvg2'

module RSyntaxTree
  class RSGenerator
    def initialize(params = {})
      new_params = {}
      fontset = {}
      params.each do |keystr, value|
        key = keystr.to_sym
        # An option given as an empty string is an option not given. An HTML
        # form posts a field for every control it carries, and a control with
        # nothing selected posts the empty string — so a form that has outlived
        # one of its own controls sends `format=` and every other option along
        # with it. Read as a value, that is a choice nobody can have made, and
        # it failed the whole request: the web UI's three Download buttons
        # returned 500 for every input, with the reason nowhere the user could
        # see it. Read as silence, the default stands, which is what the sender
        # meant.
        next if (OPTION_VALUES.key?(key) || NUMERIC_RANGES.key?(key)) &&
                (value.nil? || value.to_s.strip.empty?)

        if REMOVED_OPTIONS.key?(key)
          raise RSTError.new(+"Error: option '#{key}' was removed in RSyntaxTree 2.0",
                             code: :invalid_option, label: key.to_s,
                             hint: "Use #{REMOVED_OPTIONS[key]} instead.",
                             retryable: false)
        end
        if OPTION_VALUES.key?(key) && !OPTION_VALUES[key].include?(value.to_s)
          raise RSTError.new(+"Error: invalid value for option '#{key}': #{value.inspect}",
                             code: :invalid_option, label: key.to_s,
                             hint: "'#{key}' must be one of: #{OPTION_VALUES[key].join(', ')}.",
                             retryable: false)
        end
        # The range check reads the value as a float, and a string that is
        # not a number reads as zero. Every range used to sit clear of zero,
        # so nonsense failed the range check by accident; shear's runs through
        # it, and "abc" would have been taken as no shear at all.
        if NUMERIC_RANGES.key?(key) && !value.is_a?(Numeric) &&
           value.to_s.strip !~ /\A-?(\d+(\.\d+)?|\.\d+)\z/
          raise RSTError.new(+"Error: invalid value for option '#{key}': #{value.inspect}",
                             code: :invalid_option, label: key.to_s,
                             hint: "'#{key}' takes a number.",
                             retryable: false)
        end
        if NUMERIC_RANGES.key?(key) && !NUMERIC_RANGES[key].cover?(value.to_f)
          range = NUMERIC_RANGES[key]
          raise RSTError.new(+"Error: invalid value for option '#{key}': #{value.inspect}",
                             code: :invalid_option, label: key.to_s,
                             hint: "'#{key}' must be in the range of #{range.begin}-#{range.end}.",
                             retryable: false)
        end
        case key
        when :data
          data = value
          data = data.gsub('-AMP-', '&')
                     .gsub('-PERCENT-', "%")
                     .gsub('-PRIME-', "'")
                     .gsub('-SCOLON-', ';')
                     .gsub('-OABRACKET-', '<')
                     .gsub('-CABRACKET-', '>')
                     .gsub('¥¥', '\¥')
                     .gsub(/(?<!\\)¥/, "\\")
          # Penn Treebank input converts to bracket notation here, in the
          # library, so every path — CLI, web UI, any other caller — sees
          # the documented automatic conversion. Only '('-leading input is
          # affected; bracket notation passes through unchanged.
          new_params[key] = FormatConverter.to_bracket(data)

        when :tidy
          # One layout scale from the most spacious to the most dense:
          # "symmetric" (radical symmetrization, uniform sibling slots),
          # "off" (the traditional layout), "low" (contour packing with
          # strict leaf positions), "medium" (packing that may tuck
          # branches across rows as long as no two leaves swap their
          # left-right order), "high" (free tucking; leaf order kept per
          # row only). "on"/"compact" are accepted as aliases of low/high.
          # The separate symmetrize and tidy_nest flags this scale replaced
          # were removed in 2.0; tidy: symmetric and tidy: high say what
          # they said.
          new_params[key] = case value.to_s
                            when "high", "compact"
                              "high"
                            when "medium"
                              "medium"
                            when "low", "on", "true"
                              "low"
                            when "symmetric"
                              "symmetric"
                            else
                              "off"
                            end
        when :transparent, :polyline, :hide_default_connectors, :mirror, :derivation
          new_params[key] = switched_on?(value)
        when :color
          new_params[key] = case value.to_s
                            when "modern", "on", "true"
                              "modern"
                            when "traditional"
                              "traditional"
                            when "gray", "grey"
                              "gray"
                            else
                              "off"
                            end
        when :format
          new_params[key] = value.to_s == "lsif" ? "json" : value.to_s
        when :hyphen
          new_params[key] = value.to_s == "literal" ? "literal" : "markup"
        when :fontsize
          new_params[key] = value.to_i
        when :linewidth
          new_params[key] = value.to_f
        when :vheight, :hspacing, :shear, :vmargin
          new_params[key] = value.to_f
        when :shear_plane
          # on | off | a colour. The empty string is a form control nobody
          # touched, so the default stands — this key sits outside the value
          # tables the blanket blank-skip above covers.
          v = value.to_s.strip
          unless v.empty?
            new_params[key] = case v.downcase
                              when "on", "true", "yes", "1" then "on"
                              when "off", "false", "no", "0", "none" then "off"
                              else
                                unless COLOR_NAMES.include?(v.downcase) || v =~ /\A#(\h{3}|\h{6})\z/
                                  raise RSTError.new(+"Error: invalid value for option 'shear_plane': #{value.inspect}",
                                                     code: :invalid_option, label: "shear_plane",
                                                     hint: "'shear_plane' is on, off, a colour name, " \
                                                           "or a hex colour of 3 or 6 digits.",
                                                     retryable: false)
                                end
                                v
                              end
          end
        when :fontstyle
          # Fonts are resolved by name through fontconfig (measurement via
          # Pango, rendering via the SVG font-family attribute), so all a
          # style needs is its family fallback chain.
          style = case value.to_s
                  when "noto-sans-mono", "mono" then :mono
                  when "noto-serif", "serif" then :serif
                  when "cjk zenhei", "cjk" then :cjk
                  else :sans
                  end
          fontset[:family] = FontFamily.for_pango(style)
          new_params[:fontstyle] = style.to_s
        else
          new_params[key] = value
        end
      end

      # defaults to the following
      @params = DEFAULT_OPTS.dup
      @params.merge! new_params
      @params[:fontsize] = @params[:fontsize] * FONT_SCALING
      # fontset is populated above only when :fontstyle is passed explicitly;
      # fall back to the merged default style otherwise
      if fontset[:family].nil?
        fontset[:family] = FontFamily.for_pango(@params[:fontstyle])
      end
      @params[:fontset] = fontset
      single_x_metrics = FontMetrics.get_metrics("X", fontset[:family], @params[:fontsize], :normal, :normal)
      @global = {}
      # A derivation is written down the page: the rule that joins the
      # premises is a horizontal line across them, and the result sits under
      # it. Laid out left to right there is nothing for that line to span, and
      # the drawing came out with rules struck through the categories. There
      # is no left-to-right convention for a derivation to fall back on, so
      # the combination is refused rather than approximated.
      if @params[:derivation] == true && @params[:direction] == "ltr"
        raise RSTError.new(+"Error: a derivation cannot be drawn left to right",
                           code: :invalid_option, label: "derivation",
                           hint: "A derivation runs down the page. Use direction ttb or btt, " \
                                 "or turn derivation off.",
                           retryable: false)
      end

      # Hiding the default connectors draws them in the background colour
      # rather than skipping them. A derivation's rules are drawn as connectors
      # but they are the figure itself, not a default the drawing adds, so
      # hiding them leaves rows of categories floating with nothing joining
      # them. Refused for the same reason as left to right.
      if @params[:derivation] == true && @params[:hide_default_connectors] == true
        raise RSTError.new(+"Error: a derivation's rules cannot be hidden",
                           code: :invalid_option, label: "derivation",
                           hint: "The rules are what a derivation is drawn with, not a " \
                                 "connector added to it. Turn off hide default connectors, " \
                                 "or turn derivation off.",
                           retryable: false)
      end

      @global[:single_x_metrics] = single_x_metrics
      # A derivation labels each step with the rule it applied, written at the
      # right end of the line. Elements need to know, because the name is taken
      # out of the label before it is measured.
      @global[:derivation] = @params[:derivation] == true
      @global[:height_connector_to_text] = single_x_metrics.height / 2.0
      @global[:single_line_height] = single_x_metrics.height * 2.0
      @global[:width_half_x] = single_x_metrics.width / 2.0
      @global[:height_connector] = single_x_metrics.height * @params[:vheight]
      # Horizontal counterpart of vheight: hspacing scales every horizontal
      # gap (sibling clearance in all layout modes, tidy minimum gap,
      # margins) the way vheight scales the vertical rhythm.
      #
      # The factor is kept beside the gap it scales because the left-to-right
      # layout replaces that gap with one of its own and has to scale it by
      # the same amount. Recovering the factor by dividing the gap back out
      # would be this rule written a second time, free to drift from this one.
      @global[:hspacing] = (@params[:hspacing] || 1.0).to_f
      @global[:h_gap_between_nodes] = single_x_metrics.width * 0.8 * @global[:hspacing]
      # The font's band: how far a capital reaches above the baseline and a
      # descender below it. What the symmetric clearances of vmargin measure
      # from — the band rather than each label's own ink, so the line ends
      # line up across a level instead of following every g and y.
      @global[:cap_height] = single_x_metrics.ink_above
      xg_metrics = FontMetrics.get_metrics("Xg", fontset[:family], @params[:fontsize], :normal, :normal)
      @global[:descender] = xg_metrics.ink_height - xg_metrics.ink_above
      @global[:vmargin] = @params[:vmargin]
      @global[:box_vertical_margin] = if @params[:vmargin]
                                        single_x_metrics.height * @params[:vmargin] * 2
                                      else
                                        single_x_metrics.height * 0.8
                                      end
      # Every stroke follows the type size: linewidth 1 is 5% of it (the
      # ratio of an ordinary text rule, booktabs' \lightrulewidth), each
      # 0.5 step of the option adds another 2.5%, and a bold stroke adds
      # five percentage points. The old formula added absolute units
      # (linewidth + 1), so "1" actually meant 2 and small type got
      # disproportionately heavy lines.
      # Rounded, because these are written into the SVG as text and the
      # file is something people open and edit. Binary floating point turns
      # a line width of 1.5 into "2.4000000000000004" otherwise.
      @global[:stroke_normal] = (@params[:fontsize] * 0.05 * @params[:linewidth]).round(3)
      @global[:stroke_bold] = (@params[:fontsize] * (0.05 * @params[:linewidth] + 0.05)).round(3)
      # hyphen: literal swaps the two readings of - when a label is parsed.
      @global[:literal_hyphen] = @params[:hyphen] == "literal"
    end

    # Two gates, because neither one alone tells the truth.
    #
    # Bracket balance catches what the drawing path silently repairs: it
    # closes an unclosed bracket and drops a stray one, so a typo would
    # otherwise draw a tree the writer never asked for.
    #
    # Parsing catches what balance cannot see: label markup — an unpaired
    # underline in a word, a matrix left open where a raw space split a
    # value — passes the bracket count and then fails at draw time, which
    # is how a caller came to be told "OK" and still get an error.
    #
    # Passing both means the input is well-formed and really does draw.
    #
    # Options matter to the second gate: `hyphen: "literal"` decides whether
    # a hyphen is an underline, so validating without the caller's options
    # rejects input that draws.
    # An on/off option, read the way someone writing one would mean it.
    # This used to compare against "off" and "false" alone, so every other
    # way of saying no switched the option on: `mirror: "no"` reversed the
    # tree, `transparent: "0"` cut the background out, and a capital in
    # "Off" was enough on its own.
    OFF = ["off", "false", "no", "none", "0", ""].freeze

    def switched_on?(value)
      return false if value.nil? || value == false

      !OFF.include?(value.to_s.strip.downcase)
    end

    # Whether the input is nothing to draw. Whitespace alone counts: it
    # leaves no label behind, and reporting it as a defect in the library
    # told the caller their own fixable input was our fault. Asked without
    # strip when the bytes are not valid UTF-8, because strip raises there
    # and that input is not blank — it is malformed, which the caller
    # learns further down.
    def self.blank?(text)
      s = text.to_s
      return true if s.empty?

      s.valid_encoding? && s.strip.empty?
    end

    def self.check_data(text, params = {})
      raise RSTError.new(+"Error: input text is empty", code: :empty_input, retryable: false) if blank?(text)

      begin
        StringParser.valid?(text)
        new(params.merge(data: text)).validate!
      rescue RSTError
        raise
      rescue StandardError => e
        # Callers of this are told they get a verdict, and machine callers
        # are told they get one in JSON. A defect in the drawing code is
        # still a verdict of "no", so it goes back in the same shape rather
        # than as a Ruby backtrace — named so it is not mistaken for a
        # mistake in the input.
        raise RSTError.new(+"Error: input could not be processed (#{e.class})",
                           code: :internal_error, retryable: false)
      end
    end

    # Every option error at once. The constructor is the only judge of an
    # option, and its rules are not written out a second time here: it
    # stops at its first complaint, so it is asked again with the option
    # it complained about set aside, until it accepts what is left or
    # names nothing to set aside. Each round removes one option, so the
    # loop is as bounded as the option list.
    def self.option_errors(params)
      remaining = params.reject { |k, _| k.to_sym == :data }
      errors = []
      loop do
        begin
          new(remaining.merge(data: "[A a]"))
          break
        rescue RSTError => e
          errors << e
          key = e.label
          break if key.nil? || remaining.keys.none? { |k| k.to_s == key }

          remaining = remaining.reject { |k, _| k.to_s == key }
        end
      end
      errors
    end

    # Parse in collect mode: every label that will not parse, and every
    # rule name that turns out to have no rule behind it, recorded instead
    # of raised. The walk is the real one — the same tokens, the same
    # judgments — so what this reports and what drawing rejects cannot
    # drift apart. Returns the errors and whether the list was cut short.
    def collect_input_errors
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset],
                            @params[:fontsize], @global, collect_errors: true)
      sp.parse
      [sp.collected_errors, sp.more_errors?]
    end

    NOTE_OPTIONS = "Not every option could be read, so the input itself has " \
                   "not been checked yet; fixing the options may reveal more."
    NOTE_STRUCTURE = "The bracket structure could not be read, so the labels " \
                     "have not been checked yet; fixing it may reveal more."
    NOTE_LABELS = "Whole-tree checks (paths, output limits) run only once " \
                  "every label reads, so fixing these may reveal more."
    NOTE_TRUNCATED = " Only the first #{StringParser::COLLECTED_ERRORS_LIMIT} " \
                     "problems are listed."

    # The whole diagnosis at once, as the hash the CLI prints: every error
    # of the first stage that finds any, not just the first error found.
    # Stages are ordered so that nothing is reported whose appearance is an
    # artifact of an earlier mistake — a missing bracket shifts every token
    # after it, an unreadable hyphen option changes what counts as markup —
    # and when a stage stops the walk, the note says that fixing what is
    # listed may reveal more. check_data keeps its contract (raise the
    # first error) for callers that want a verdict rather than a list.
    def self.diagnose(text, params = {})
      errors = []
      note = nil
      if blank?(text)
        errors << RSTError.new(+"Error: input text is empty", code: :empty_input, retryable: false)
      else
        begin
          errors = option_errors(params)
          if errors.any?
            note = NOTE_OPTIONS
          else
            StringParser.valid?(text)
            gen = new(params.merge(data: text))
            collected, truncated = gen.collect_input_errors
            if collected.any?
              errors = collected
              note = NOTE_LABELS
              note += NOTE_TRUNCATED if truncated
            else
              gen.validate!
            end
          end
        rescue RSTError => e
          errors << e
          note = NOTE_STRUCTURE if %i[empty_brackets unbalanced_brackets].include?(e.code)
        rescue StandardError => e
          # The same promise check_data makes: a defect anywhere in here —
          # the option probing included — is still a verdict of "no", in
          # the same shape, not a backtrace.
          errors << RSTError.new(+"Error: input could not be processed (#{e.class})",
                                 code: :internal_error, retryable: false)
        end
      end

      return { "ok" => true } if errors.empty?

      result = { "ok" => false, "errors" => errors.map(&:error_entry) }
      result["note"] = note if note
      result["reference"] = RSTError::REFERENCE
      result
    end

    # Generate, and throw the result away. Parsing alone leaves out the
    # checks that only happen once the tree is laid out — a movement path
    # with one end, a line with three — so validation that stopped at the
    # parser passed input the drawing then rejected, which is the failure
    # this validation exists to prevent.
    #
    # Which generation depends on the format asked for, because the formats
    # can refuse different things: a tree can be too wide for a raster
    # surface while remaining a perfectly good SVG. Everything up to the
    # last point where a format is known to say no is done; painting the
    # tree onto the surface, which is most of the cost and refuses nothing
    # this knows of, is not. A surface inside Cairo's limits but large
    # enough to exhaust memory would still fail at that painting, so this is
    # where validation is a strong guess rather than a guarantee.
    def validate!
      case @params[:format]
      when "png" then raster_surface_for(draw_svg, &:finish)
      when "pdf" then pdf_surface_for(draw_svg, StringIO.new, &:finish)
      when "json" then draw_json
      when "tikz" then draw_tikz
      else draw_svg
      end
      true
    end

    # The surface a raster format needs. Making it is where a tree too big
    # to draw is found out — Cairo says so, nothing here knows the limit —
    # and it is cheap next to painting the tree onto it, which is why
    # validation makes one and stops there.
    def raster_surface_for(svg)
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, dim.width, dim.height)
      yield surface if block_given?
      [rsvg, surface]
    rescue Cairo::InvalidSize
      raise RSTError.new(+"Error: the result syntree is too big", code: :result_too_big, retryable: false)
    end

    # The same for PDF, which in practice refuses nothing: a page 400,000
    # points wide is made without complaint where a raster surface stops at
    # 32,767. Kept in the same shape as the raster path so that validation
    # asks the same question of both, and so a future Cairo that does refuse
    # a page size is heard.
    def pdf_surface_for(svg, target)
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::PDFSurface.new(target, dim.width, dim.height)
      yield surface if block_given?
      [rsvg, surface]
    rescue Cairo::InvalidSize
      raise RSTError.new(+"Error: the result syntree is too big", code: :result_too_big, retryable: false)
    end

    def draw_png(binary = false)
      surface = nil
      context = nil
      b = nil
      rsvg, surface = raster_surface_for(draw_svg)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      b = StringIO.new
      surface.write_to_png(b)
      binary ? b : b.string
    ensure
      b&.close unless binary
      surface&.finish
      context&.destroy
    end

    def draw_pdf(binary = false)
      surface = nil
      context = nil
      b = nil
      b = StringIO.new
      rsvg, surface = pdf_surface_for(draw_svg, b)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      surface.finish
      binary ? b : b.string
    ensure
      b&.close unless binary
      context&.destroy
    end

    def draw_svg
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      graph = SVGGraph.new(sp.get_elementlist, @params, @global)
      graph.svg_data
    end

    def draw_json
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      graph = JSONGraph.new(sp.get_elementlist, @params, @global)
      graph.json_data
    end

    # The name the JSON output wore from 1.11.0 to 2.0.0; removed in 3.0.
    def draw_lsif
      draw_json
    end

    def draw_tikz(standalone: false, font: nil)
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      generator = TikZGenerator.new(sp.get_elementlist, @params)
      generator.generate(standalone: standalone, font: font)
    end
  end
end
