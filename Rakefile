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

# Add new task for macOS environment configuration

desc "Configure Bundler build options for macOS"
task :setup_macos do
    require "rbconfig"
    host_os = RbConfig::CONFIG['host_os']

    # Check if the host OS is macOS (Darwin)

    if host_os =~ /darwin/
        puts "macOS detected. Setting up build options for native extensions..."

        gems_with_options = {
            "gobject-introspection" => '--with-ldflags=-Wl,-undefined,dynamic_lookup',
            "cairo-gobject"         => '--with-ldflags=-Wl,-undefined,dynamic_lookup',
            "gio2"                  => '--with-ldflags=-Wl,-undefined,dynamic_lookup'
        }

        # Configure each gem with the necessary ldflags option using Bundler config command

        gems_with_options.each do |gem_name, flags|
            command = "bundle config build.#{gem_name} \"#{flags}\""
            puts "Executing: #{command}"
            unless system(command)
                abort("Failed to execute command: #{command}")
            end
        end

        puts "macOS setup complete. Please run 'bundle install' after this."
    else
        puts "This setup task is intended for macOS environments. Current OS: #{host_os}"
    end
end
