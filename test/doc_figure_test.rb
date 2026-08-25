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
  FIGURES = File.join(DOCS, "assets", DocFigures::DIRECTORY)

  def examples
    DocFigures.all(DOCS)
  end

  def test_the_manual_has_examples_to_draw
    refute_empty examples, "no drawing examples found in the manual"
  end

  def test_every_example_has_its_figure
    missing = examples.reject { |code| File.exist?(File.join(FIGURES, "#{DocFigures.name(code)}.svg")) }
    assert_empty missing.map { |code| code.lines.first.strip },
                 "the manual has examples with no figure — run rake docker_generate"
  end

  # A figure whose code has gone leaves a file nothing points at, and the
  # directory would grow by one with every rewording.
  def test_no_figure_outlives_its_example
    wanted = examples.map { |code| "#{DocFigures.name(code)}.svg" }
    orphans = Dir.glob("doc-*.svg", base: FIGURES) - wanted
    assert_empty orphans, "figures for code no longer in the manual"
  end

  # Named for the code, so the same example in both manuals is drawn once.
  def test_the_two_manuals_share_their_figures
    en = DocFigures.examples(File.join(DOCS, "documentation.md"))
    ja = DocFigures.examples(File.join(DOCS, "documentation_ja.md"))
    shared = en.map { |c| DocFigures.name(c) } & ja.map { |c| DocFigures.name(c) }
    refute_empty shared, "the manuals share no example"
  end

  # Every example the manual offers has to draw. One that does not is a reader
  # copying it into the editor and being told it is wrong.
  def test_every_example_draws
    examples.each do |code|
      RSyntaxTree::RSGenerator.new(DEFAULT_OPTS.merge(DocFigures.options(code))).draw_svg
    rescue RSTError => e
      flunk "#{code.lines.first.strip}: #{e.message}"
    end
  end
end
