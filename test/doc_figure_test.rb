# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../dev/doc_figures"

# The manual shows a figure beside each drawing example, and the figure is named
# for the code it was drawn from. That is what keeps the pair honest: edit the
# code and it asks for a figure nobody has drawn, which is this test failing
# rather than a reader being shown the tree the example used to make.
#
# Run `rake docker_generate` to draw them.
class DocFigureTest < Minitest::Test
  DOCS = File.expand_path(File.join(__dir__, "..", "docs"))
  MANUALS = DocFigures::MANUALS
  FIGURES = File.join(DOCS, "assets", DocFigures::DIRECTORY)

  def examples
    DocFigures.all(DOCS)
  end

  def test_the_manual_has_examples_to_draw
    refute_empty examples, "no drawing examples found in the manual"
  end

  def test_every_example_has_its_figure
    missing = examples.reject { |code, _| File.exist?(File.join(FIGURES, "#{DocFigures.name(code)}.svg")) }
    assert_empty missing.map { |code, _| code.lines.first.strip },
                 "the manual has examples with no figure — run rake docker_generate"
  end

  # A figure whose code has gone leaves a file nothing points at, and the
  # directory would grow by one with every rewording.
  def test_no_figure_outlives_its_example
    wanted = examples.map { |code, _| "#{DocFigures.name(code)}.svg" }
    orphans = Dir.glob("doc-*.svg", base: FIGURES) - wanted
    assert_empty orphans, "figures for code no longer in the manual"
  end

  # Named for the code, so the same example in both manuals is drawn once.
  def test_the_two_manuals_share_their_figures
    en = DocFigures.examples(File.join(DOCS, "documentation.md"))
    ja = DocFigures.examples(File.join(DOCS, "documentation_ja.md"))
    shared = en.map { |c, _| DocFigures.name(c) } & ja.map { |c, _| DocFigures.name(c) }
    refute_empty shared, "the manuals share no example"
  end

  # The figure shown beside an example has to be the figure of that example.
  # Naming it after the code is only half the guard: the manual names it too, in
  # the include and in the grid's class, and those are written by hand. An
  # example rewritten without its references updated leaves the reader looking
  # at the tree it used to make — or, once the old figure has been swept up, at
  # nothing at all, which is how nine of these came to point at figures that no
  # longer existed.
  def test_each_example_shows_its_own_figure
    MANUALS.each do |manual|
      File.read(File.join(DOCS, manual), encoding: "utf-8")
          .scan(%r{<div class="grid[^"]*" markdown="1">.*?\n</div>}m) do |block|
        code = block[/```text\n(.*?)\n```/m, 1]
        next unless code

        expected = DocFigures.name(code.strip)
        block.scan(/doc_figure_sizes\['(doc-[0-9a-f]+)'\]|name="(doc-[0-9a-f]+)"/) do
          named = Regexp.last_match(1) || Regexp.last_match(2)
          assert_equal expected, named,
                       "#{manual}: an example is shown beside another example's figure"
        end
      end
    end
  end

  # Every example the manual offers has to draw. One that does not is a reader
  # copying it into the editor and being told it is wrong.
  def test_every_example_draws
    examples.each do |code, asked|
      RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(DocFigures.options(code, asked))).draw_svg
    rescue RSTError => e
      flunk "#{code.lines.first.strip}: #{e.message}"
    end
  end
end
