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

desc "Generate SVG and PNG example images"
task :generate do
  require_relative "devel/generate_examples"
end
