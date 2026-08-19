# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../dev/example_options"

# Every published gallery example must pass validation with its own options.
# Validation shares the parser with drawing, so an example that fails here
# cannot draw either.
class GalleryValidationTest < Minitest::Test
  examples_dir = File.expand_path(File.join(__dir__, "..", "docs", "_examples"))

  Dir.glob("*.md", base: examples_dir).sort.each do |md|
    name, opts = ExampleOptions.load(File.join(examples_dir, md))

    define_method "test_#{name}_validates" do
      assert RSyntaxTree::RSGenerator.check_data(opts[:data], opts),
             "#{name} should validate with its own options"
    end
  end
end
