# frozen_string_literal: true

#==========================
# escape.rb
#==========================
#
# Turns arbitrary text into notation that draws as that text.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

module RSyntaxTree
  # The characters the notation reads as markup, each written as itself by
  # a backslash. The backslash comes first so that the others are escaped
  # once, not twice. A yen sign is here because the reader treats it as a
  # backslash for keyboards that have no other.
  ESCAPED_CHARACTERS = %w[\\ [ ] < > ^ + * _ = ~ | # { } % @ ¥].freeze

  ESCAPE_CONTEXTS = %i[word phrase label cell].freeze

  # The web interface's transport spellings of characters a form cannot
  # carry, read out of the input before anything else. Under hyphen: markup
  # the hyphens are escaped and nothing matches; under :literal they would
  # be read, so a backslash goes in after the first hyphen — an escape the
  # reader does not know, whose backslash it drops — and the text survives.
  TRANSPORT_PLACEHOLDERS = %w[AMP PERCENT PRIME SCOLON OABRACKET CABRACKET].freeze

  # A line of three or more hyphens and nothing else is the horizontal rule.
  RULE_LINE = /\A-{3,}\z/

  # Notation that draws as +text+, for a program writing notation from
  # strings it did not choose — a tagger's tokens, a corpus's words.
  # Written here rather than in every such program, because a copy of the
  # escaping rules kept elsewhere would drift from the notation as it
  # changes, and the drift would show as a different figure drawn without
  # complaint. The test for this method draws each result and checks that
  # the text came out, so the rules are never restated, only exercised.
  #
  # +as+ says where the text will stand, which decides what whitespace
  # means: a :word is one leaf or one label (a space inside it becomes <>),
  # a :phrase is a leaf of several words (spaces stay, so the leaf gets a
  # triangle), a :label is a node label (like a word, with a newline kept
  # as a line break), and a :cell is one cell of a column-aligned or
  # matrix label (tabs and newlines become the column and row breaks).
  #
  # +hyphen+ must match the option the figure is drawn with. Under :markup
  # a hyphen is escaped; under :literal a bare hyphen is already itself,
  # and the escaped form means an underline instead — so there is no
  # notation that reads as a hyphen under both, and the caller has to say.
  #
  # +apostrophe+ :curly leaves a straight apostrophe to be set as a curly
  # one, which is what the notation does; :keep escapes it so it stays
  # straight, for text that must come out exactly as given.
  #
  # One text has no spelling under hyphen: :literal — a line of nothing but
  # three or more hyphens, which is the horizontal rule and draws as one —
  # and asking for it raises ArgumentError rather than returning notation
  # that draws an empty leaf. Empty and all-whitespace text is returned as
  # the whitespace it holds, which draws as a blank; a caller building a
  # tree from tokens will usually want to drop such tokens first.
  def self.escape(text, as: :word, hyphen: :markup, apostrophe: :curly)
    unless ESCAPE_CONTEXTS.include?(as)
      raise ArgumentError, "as: must be one of #{ESCAPE_CONTEXTS.join(', ')}"
    end
    raise ArgumentError, "hyphen: must be :markup or :literal" unless %i[markup literal].include?(hyphen)
    raise ArgumentError, "apostrophe: must be :curly or :keep" unless %i[curly keep].include?(apostrophe)

    s = text.to_s
    if as == :phrase
      words = s.split(/\s+/).reject(&:empty?)
      # One word alone is the whole leaf; with company, hyphens are text.
      refuse_rule_line(s, hyphen) if hyphen == :literal && words.length == 1 && words.first.match?(RULE_LINE)
      return words.map { |w| escape_text(w, :word, hyphen, apostrophe) }.join(" ")
    end

    if hyphen == :literal
      # A newline is a line break in a label or a cell, and a space in a word.
      lines = %i[label cell].include?(as) ? s.split(/\r\n?|\n/, -1) : [s]
      lines.each { |line| refuse_rule_line(s, hyphen) if line.match?(RULE_LINE) }
    end
    escape_text(s, as, hyphen, apostrophe)
  end

  # The character work, once the text has been accepted.
  def self.escape_text(s, as, hyphen, apostrophe)
    # Every replacement is a block: as a replacement string a backslash is
    # read for backreferences, and `\\'` and `\\+` are two of them.
    out = s.gsub(/[#{Regexp.escape(ESCAPED_CHARACTERS.join)}]/) { |c| "\\#{c}" }
    out = out.gsub("-") { "\\-" } if hyphen == :markup
    if hyphen == :literal
      out = out.gsub(/-(#{TRANSPORT_PLACEHOLDERS.join('|')})-/) { "-\\#{Regexp.last_match(1)}-" }
    end
    out = out.gsub("'") { "\\'" } if apostrophe == :keep
    out = out.gsub(/\r\n?|\n/) { "\\n" } if %i[label cell].include?(as)
    out = out.gsub("\t") { "\\t" } if as == :cell
    # A CRLF is one break, so one space, as it is one break in a label.
    out.gsub(/\r\n|\s/) { "<>" }
  end
  private_class_method :escape_text

  def self.refuse_rule_line(text, hyphen)
    raise ArgumentError,
          "no notation draws #{text.inspect} under hyphen: #{hyphen.inspect}: a line of " \
          "nothing but hyphens is the horizontal rule. Draw with hyphen: :markup."
  end
  private_class_method :refuse_rule_line
end
