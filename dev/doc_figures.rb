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

  # The bracket notation in every drawing example, in the order it appears.
  # A fenced block is a drawing example when it is `text` and starts a tree.
  def examples(manual)
    lines = File.read(manual, encoding: "utf-8").lines(chomp: true)
    found = []
    index = 0
    while index < lines.length
      if lines[index] == "```text"
        body = []
        index += 1
        while index < lines.length && !lines[index].start_with?("```")
          body << lines[index]
          index += 1
        end
        code = body.join("\n").strip
        found << code if code.start_with?("[")
      end
      index += 1
    end
    found
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
  def options(code)
    base = { data: code, color: "off", fontstyle: "serif", fontsize: 16,
             tidy: "low", linewidth: 1, hyphen: "literal" }
    return base unless code.include?('\t') && code.match?(/\\t\s*[<>]/)

    base.merge(derivation: "on", direction: "btt", leafstyle: "nothing",
               vheight: 0.5, hspacing: 2.0)
  end
end
