# frozen_string_literal: true

require "digest"

# The figures beside the code in the manual. Each drawing example there is a
# fenced `text` block holding bracket notation, and each gets an SVG drawn from
# exactly that text, named for it: change the code and the name changes with it,
# so a figure can never quietly belong to code that has moved on.
#
# The two manuals hold the same examples, so a block that appears in both is
# drawn once and shown in both.
module DocFigures
  module_function

  MANUALS = ["documentation.md", "documentation_ja.md"].freeze
  DIRECTORY = "doc"

  # An example drawn with something other than the ordinary settings says so on
  # the line above its code, where whoever edits the example will see it:
  #
  #   <!-- figure: direction=ltr -->
  #
  # Kept out of the code block itself, so what a reader copies is only the tree.
  SETTINGS = /<!--\s*figure:\s*(.+?)\s*-->/

  # The bracket notation in every drawing example, in the order it appears.
  # A fenced block is a drawing example when it is `text` and starts a tree.
  def examples(manual)
    lines = File.read(manual, encoding: "utf-8").lines(chomp: true)
    found = []
    index = 0
    while index < lines.length
      if lines[index] == "```text"
        # What the line above asked for, if it asked for anything.
        asked = index.positive? ? lines[index - 1][SETTINGS, 1] : nil
        body = []
        index += 1
        while index < lines.length && !lines[index].start_with?("```")
          body << lines[index]
          index += 1
        end
        code = body.join("\n").strip
        found << [code, asked] if code.start_with?("[")
      end
      index += 1
    end
    found
  end

  # `direction=ltr color=modern` as the generator wants it. A value that reads
  # as a number becomes one, since the options that take a number will not have
  # a string.
  def parse(asked)
    return {} if asked.nil? || asked.strip.empty?

    asked.split(/\s+/).to_h do |pair|
      key, value = pair.split("=", 2)
      [key.to_sym, /\A-?\d+(\.\d+)?\z/.match?(value) ? value.to_f : value]
    end
  end

  # What the figure for a piece of code is called. Taken from the code, so the
  # name follows it: an edited example asks for a figure that has not been
  # drawn, which is what doc_figure_test.rb reports.
  def name(code)
    "doc-#{Digest::SHA256.hexdigest(code)[0, 8]}"
  end

  # Every example in the manuals, without repeats.
  def all(doc_dir)
    MANUALS.flat_map { |m| examples(File.join(doc_dir, m)) }.uniq
  end

  # How the manuals are drawn: no colour, the serif face the gallery uses, and
  # the connectors a tree is drawn with unless the example is a derivation.
  def options(code, asked = nil)
    base = { data: code, color: "off", fontstyle: "serif", fontsize: 16,
             tidy: "low", linewidth: 1, hyphen: "literal" }
    if code.include?('\\t') && code.match?(/\\t\s*[<>]/)
      base = base.merge(derivation: "on", direction: "btt", leafstyle: "nothing",
                        vheight: 0.5, hspacing: 2.0)
    end
    base.merge(parse(asked))
  end
end
