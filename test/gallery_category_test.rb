# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"
require "yaml"

# The gallery lists its categories in the order _data/categories.yml gives.
# Before that file the order was whatever Liquid's group_by returned — the
# order the categories first appear among the examples, which is the order
# they were added in — so a new category always landed at the bottom of the
# page however well it belonged higher up.
#
# A list like that is only as good as what keeps it level with the examples.
# The template shows an unlisted category rather than dropping it, which is
# the right thing for a reader and the wrong thing to leave unsaid, so the
# mistake is named here instead.
class GalleryCategoryTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  # Kept off the public page, and so out of the order.
  INTERNAL = %w[Test Error].freeze

  def listed
    YAML.load_file(File.join(ROOT, "docs", "_data", "categories.yml"))["order"]
  end

  def used
    Dir.glob("*.md", base: File.join(ROOT, "docs", "_examples")).sort.filter_map do |file|
      category = YAML.load_file(File.join(ROOT, "docs", "_examples", file))["category"].to_s
      category unless category.empty? || INTERNAL.include?(category)
    end.uniq
  end

  def test_every_category_an_example_uses_is_placed_in_the_order
    assert_empty used - listed,
                 "categories with no place in docs/_data/categories.yml: they would " \
                 "be shown at the end of the page, after everything that has one"
  end

  def test_the_order_names_no_category_that_has_left
    assert_empty listed - used,
                 "categories in docs/_data/categories.yml that no example uses"
  end

  def test_the_order_names_each_category_once
    assert_equal listed.uniq, listed, "a category listed twice"
  end

  # Miscellaneous is where a figure goes when it belongs nowhere else, so it
  # reads as the end of the page rather than as a category among the others.
  def test_miscellaneous_comes_last
    assert_equal "Miscellaneous", listed.last
  end
end
