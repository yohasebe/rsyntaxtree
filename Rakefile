# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "yaml"
require_relative 'lib/rsyntaxtree'
require_relative 'lib/rsyntaxtree/utils'

# task default: "test"

Rake::TestTask.new do |task|
  task.pattern = "test/*_test.rb"
  task.warning = false
end

desc "Generate SVG and PNG example images locally"
task :generate do
  require_relative "dev/generate_examples"
end

desc "Docker image Build"
task :docker_build do
  `docker build ./ -t rsyntaxtree_devel`
end

desc "Generate SVG and PNG example images using Docker image"
task :docker_generate do
  docpath = File.expand_path(File.join(__dir__, "docs"))
  `docker build ./ -t rsyntaxtree_devel`
  `docker run --rm -v #{docpath}:/rsyntaxtree/hostdocs rsyntaxtree_devel ruby /rsyntaxtree/dev/generate_examples.rb /rsyntaxtree/hostdocs`
  `cat #{docpath}/generate_examples.log`
end
