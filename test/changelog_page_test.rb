# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../dev/changelog_page"

# The site's changelog page is built from CHANGELOG.md and committed, so an
# edit to the record with no rebuild would leave the site telling an older
# story. Building it again here is what notices — the same arrangement that
# guards the llms files.
class ChangelogPageTest < Minitest::Test
  PAGE = File.join(ChangelogPage::ROOT, "docs", "changelog.md")

  def test_the_page_is_current
    assert_equal ChangelogPage.body, File.read(PAGE),
                 "docs/changelog.md is out of date; run `rake changelog_page`"
  end

  # Every release heading carries a full date. The record used to date its
  # releases by month, so the eleven releases of one busy month all read
  # "2026-08" and the date carried nothing; two headings were plainly wrong.
  # The dates come from the git tags, which is where the truth was all along.
  def test_every_release_is_dated_to_the_day
    File.read(PAGE).scan(/^## \[(\d[\d.]*)\] - (.*)$/) do |version, date|
      assert_match(/\A\d{4}-\d{2}-\d{2}\z/, date,
                   "#{version}: dated '#{date}' rather than to the day")
    end
  end
end
