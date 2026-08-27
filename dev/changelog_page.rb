# frozen_string_literal: true

# The changelog page the documentation site serves, built from CHANGELOG.md.
# The file at the root is the record; this is its projection onto the site, so
# that reading what changed does not require a trip to the repository. Nothing
# here is authored — a page written by hand beside the record would drift from
# it, which is the same reason the llms files are generated.
module ChangelogPage
  module_function

  ROOT = File.expand_path(File.join(__dir__, ".."))

  FRONT_MATTER = <<~YAML
    ---
    title: RSyntaxTree
    layout: default
    ---

  YAML

  HEADER = <<~MD
    # Changelog
    {:.no_toc}

    [Documentation](https://yohasebe.github.io/rsyntaxtree/documentation) |
    [Example Gallery](https://yohasebe.github.io/rsyntaxtree/examples) |
    [Web App](https://yohasebe.com/rsyntaxtree)

  MD

  def body
    changelog = File.read(File.join(ROOT, "CHANGELOG.md"))
    # The record opens with its own "# Changelog" heading; the page supplies
    # one with the site's furniture around it instead.
    entries = changelog.sub(/\A# Changelog\s*/, "")
    FRONT_MATTER + HEADER + entries
  end

  def write
    path = File.join(ROOT, "docs", "changelog.md")
    File.write(path, body)
    puts format("%-30s %6d bytes", "docs/changelog.md", body.bytesize)
  end
end

ChangelogPage.write if $PROGRAM_NAME == __FILE__
