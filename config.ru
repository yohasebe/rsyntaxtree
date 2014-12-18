path = File.expand_path("../", __FILE__)

require 'sinatra'
require "#{path}/app"

$SUB_DIRECTORY = "/rsyntaxtree"

run Sinatra::Application