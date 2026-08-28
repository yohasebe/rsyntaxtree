# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"

require_relative "../lib/rsyntaxtree"

# FORMATS is the single list every part of the CLI reads the output formats
# from — the validator, the help text, and the error message. These tests
# fix what the list contains and that the CLI's words still match it.
class FormatsTest < Minitest::Test
  BIN_PATH = File.expand_path("../bin/rsyntaxtree", __dir__)

  def test_every_format_has_a_draw_method
    FORMATS.each do |fmt|
      assert RSyntaxTree::RSGenerator.method_defined?("draw_#{fmt}"),
             "FORMATS lists #{fmt} but RSGenerator has no draw_#{fmt}"
    end
  end

  def test_every_format_has_an_extension
    assert_equal FORMATS.sort, FORMAT_EXTENSIONS.keys.sort
  end

  def test_format_list_is_stable
    assert_equal %w[png pdf svg lsif tikz], FORMATS
  end

  def test_cli_rejects_an_unknown_format_with_the_same_words
    _out, err, status = Open3.capture3("ruby", BIN_PATH, "-f", "bmp", "[S a]")
    refute status.success?
    assert_includes err, "must be png, pdf, svg, lsif, or tikz"
  end

  def test_cli_tikz_writes_a_tex_file
    Dir.mktmpdir do |dir|
      _out, _err, status = Open3.capture3("ruby", BIN_PATH, "-f", "tikz", "-o", dir, "[S a]")
      assert status.success?
      assert File.exist?(File.join(dir, "syntree.tex"))
    end
  end
end
