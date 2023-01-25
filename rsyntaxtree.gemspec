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
  s.required_ruby_version = Gem::Requirement.new(">= 2.6")
  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "optimist", "~> 3.0", ">= 3.0.1"
  s.add_runtime_dependency "parslet"
  s.add_runtime_dependency "rmagick", "~> 4.2", ">= 4.2.3"
  s.add_runtime_dependency "rsvg2"

  s.add_development_dependency "yaml"
end
