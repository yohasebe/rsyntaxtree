path = File.expand_path("../", __FILE__)

require 'sinatra'
require "#{path}/app"

run Sinatra::Application