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
    missing = examples.reject { |code, asked| File.exist?(File.join(FIGURES, "#{DocFigures.name(code, asked)}.svg")) }
    assert_empty missing.map { |code, _| code.lines.first.strip },
                 "the manual has examples with no figure — run rake docker_generate"
  end

  # A figure whose code has gone leaves a file nothing points at, and the
  # directory would grow by one with every rewording.
  def test_no_figure_outlives_its_example
    wanted = examples.map { |code, asked| "#{DocFigures.name(code, asked)}.svg" }
    orphans = Dir.glob("doc-*.svg", base: FIGURES) - wanted
    assert_empty orphans, "figures for code no longer in the manual"
  end

  # A figure git ignores is a figure the published site does not have. These
  # went uncommitted from the day they were first drawn: `doc/` in .gitignore,
  # written for RDoc's output at the root, was unanchored and matched
  # docs/assets/doc as well. Nothing said so — the files were on disk, the local
  # preview served them from disk, the tests above found them on disk, and only
  # the site, built from what was committed, was missing all of them.
  #
  # Asked as "is this ignored", not "is this committed", so that a figure just
  # redrawn and not yet added does not fail the suite.
  def test_the_figures_are_not_ignored
    Dir.chdir(File.dirname(DOCS)) do
      skip "not a git work tree" unless system("git rev-parse --git-dir", out: File::NULL, err: File::NULL)

      paths = Dir.glob("doc-*.svg", base: FIGURES)
                 .map { |f| File.join("docs", "assets", DocFigures::DIRECTORY, f) }
      refute_empty paths, "no figures to check"
      ignored = IO.popen(["git", "check-ignore", "--stdin"], "r+") do |io|
        io.puts(paths)
        io.close_write
        io.read
      end
      assert_empty ignored.split("\n"), "figures the manual shows that git is set to ignore"
    end
  end

  # Named for the code, so the same example in both manuals is drawn once.
  def test_the_two_manuals_share_their_figures
    en = DocFigures.examples(File.join(DOCS, "documentation.md"))
    ja = DocFigures.examples(File.join(DOCS, "documentation_ja.md"))
    shared = en.map { |c, a| DocFigures.name(c, a) } & ja.map { |c, a| DocFigures.name(c, a) }
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

        asked = block[DocFigures::SETTINGS, 1]
        expected = DocFigures.variants(asked).map { |v| DocFigures.name(code.strip, v) }
        shown = block.scan(/name="(doc-[0-9a-f]+)"/).flatten
        sized = block.scan(/doc_figure_sizes\['(doc-[0-9a-f]+)'\]/).flatten

        assert_equal expected, shown,
                     "#{manual}: an example does not show its own figures, or not all of them"
        assert_empty sized - expected,
                     "#{manual}: a grid takes its width from another example's figure"
      end
    end
  end

  # An example drawn twice with different settings is two figures. Named for
  # the code alone they would be one, three references would share it, and
  # whichever drawing ran last would be the one all three showed.
  def test_settings_are_part_of_the_name
    code = "[S [NP a] [VP b]]"
    assert_equal DocFigures.name(code), DocFigures.name(code, nil),
                 "an example that asks for nothing keeps the name its code alone gives it"
    refute_equal DocFigures.name(code, "fontstyle=sans"), DocFigures.name(code, "fontstyle=mono"),
                 "two settings, two figures"
    refute_equal DocFigures.name(code), DocFigures.name(code, "fontstyle=sans")
  end

  # `|` in a settings line lists the ways one example is to be drawn.
  def test_a_settings_line_may_list_several_variants
    assert_equal [nil], DocFigures.variants(nil)
    assert_equal [nil], DocFigures.variants("  ")
    assert_equal ["direction=ltr"], DocFigures.variants("direction=ltr")
    assert_equal %w[fontstyle=sans fontstyle=serif fontstyle=mono],
                 DocFigures.variants("fontstyle=sans | fontstyle=serif | fontstyle=mono")
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
