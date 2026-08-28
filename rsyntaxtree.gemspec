# frozen_string_literal: true

require_relative "lib/rsyntaxtree/version"

Gem::Specification.new do |s|
  s.name        = "rsyntaxtree"
  s.version     = RSyntaxTree::VERSION
  s.authors     = ["Yoichiro Hasebe"]
  s.email       = ["yohasebe@gmail.com"]
  s.homepage    = "http://github.com/yohasebe/rsyntaxtree"
  s.summary     = "RSyntaxTree is a graphical syntax tree generator written in Ruby"
  s.description = "Syntax tree generator made with Ruby"
  s.licenses    = ["MIT"]
  s.required_ruby_version = ">= 3.2.0"
  # What the gem carries is what someone installing it needs: the library, the
  # command, the notation reference the command prints, and the files that say
  # what this is, how to cite it and under what licence. The rest of the
  # repository is for working on it — the documentation site and its gallery,
  # the scripts that build them, the tests, the CI and container setup, the
  # bundle and the rake tasks — and whoever wants those clones the repository.
  development = ["docs/", "dev/", "img/", "test/", ".github/"]
  development_files = [".gitattributes", ".gitignore", ".ruby-version",
                       "Dockerfile", "Gemfile", "Rakefile"]
  s.files         = `git ls-files`.split("\n").reject do |path|
                      development.any? { |dir| path.start_with?(dir) } ||
                        development_files.include?(path)
                    end
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Four, and each is used: optimist parses the command line, parslet parses
  # the markup inside a label, pango measures the text, rsvg2 draws the PNG
  # and the PDF. Two of them build against a system library — pango and
  # librsvg — which is what an install of this gem asks a machine for.
  s.add_runtime_dependency "optimist", ">= 3.0.1"
  s.add_runtime_dependency "pango"
  s.add_runtime_dependency "parslet"
  s.add_runtime_dependency "rsvg2"

  s.add_development_dependency "minitest"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "rake"
end
