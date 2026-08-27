#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "llm_payload"

targets = {
  File.join(LlmPayload::ROOT, "lib", "rsyntaxtree", "notation_examples.md") => LlmPayload.examples_document,
  File.join(LlmPayload::ROOT, "docs", "llms.txt") => LlmPayload.index_document,
  File.join(LlmPayload::ROOT, "docs", "notation.txt") => LlmPayload.notation_document,
  File.join(LlmPayload::ROOT, "docs", "llms-full.txt") => LlmPayload.full_document
}

targets.each do |path, content|
  changed = !File.exist?(path) || File.read(path) != content
  File.write(path, content)
  rel = path.sub("#{LlmPayload::ROOT}/", "")
  puts format("%-40s %7d bytes%s", rel, content.bytesize, changed ? "" : "  (unchanged)")
end
