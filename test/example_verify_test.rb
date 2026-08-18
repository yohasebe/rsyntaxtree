# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "nokogiri"

require_relative '../lib/rsyntaxtree'
require_relative '../lib/rsyntaxtree/utils'
require_relative '../dev/example_options'

class ExampleParserTest < Minitest::Test
  examples_dir = File.expand_path(File.join(__dir__, "..", "docs", "_examples"))

  Dir.glob("*.md", base: examples_dir).map do |md|
    name, opts = ExampleOptions.load(File.join(examples_dir, md))

    svg = RSyntaxTree::RSGenerator.new(opts).draw_svg
    document = Nokogiri::XML(svg)

    define_method "test_#{name}" do
      assert_equal document.errors.empty?, true
    end
  end
end
