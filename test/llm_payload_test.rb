# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../dev/llm_payload"

# The payload is built from the notation reference, the manual and the gallery.
# Nothing regenerates it on its own, so an edit to any of those leaves the built
# files behind, and what a model is handed stops matching what the tool reads.
# Building it again here is what notices.
class LlmPayloadTest < Minitest::Test
  ROOT = LlmPayload::ROOT

  {
    "lib/rsyntaxtree/notation_examples.md" => :examples_document,
    "docs/llms.txt" => :index_document,
    "docs/llms-full.txt" => :full_document
  }.each do |rel, builder|
    define_method "test_#{File.basename(rel).tr('.-', '__')}_is_up_to_date" do
      path = File.join(ROOT, rel)
      assert File.exist?(path), "#{rel} is missing; run `rake llm_payload`"
      assert_equal File.read(path), LlmPayload.public_send(builder),
                   "#{rel} is out of date; run `rake llm_payload`"
    end
  end

  def test_every_published_example_is_present
    published = Dir.glob("*.md", base: File.join(ROOT, "docs", "_examples")).count do |md|
      front = YAML.load_file(File.join(ROOT, "docs", "_examples", md))
      !["Test", "Error"].include?(front["category"].to_s)
    end
    assert_equal published, LlmPayload.examples.size
  end

  # The two tables the manual pulls in through Jekyll carry the box, circle and
  # escape notation. An unresolved include tag would drop exactly the part a
  # model needs, and would not otherwise show up as a failure.
  def test_the_manual_carries_the_included_tables
    manual = LlmPayload.manual
    refute_includes manual, "{% include", "a Jekyll include was left unresolved"
    assert_includes manual, "`|/|` →", "the box and circle table is missing"
    assert_includes manual, "`\\<` →", "the escape table is missing"
  end

  # Some of that notation contains the character a markdown table splits on.
  def test_notation_holding_a_pipe_survives
    assert_includes LlmPayload.manual, "`|abc|` →"
  end
end
