#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'sinatra'
require 'haml'
require 'base64'
require './helpers/helpers'
require './lib/rsyntaxtree'

include Helpers

set :public_folder, File.dirname(__FILE__) + '/public'

configure do
  enable :sessions
end

get '/' do #
  haml :index
end

post '/check' do                        
  data = params["data"]
  result = RSGenerator.check_data(data)
  return result ? "true" : "false"
end

get '/draw_png' do
  rs_generator = RSGenerator.new(params)
  content_type "image/png"
  rs_generator.draw_tree
end

post '/draw_png' do  
  basename = "syntree.png"
  rs_generator = RSGenerator.new(params)
  png_blob = rs_generator.draw_png
  response.headers['content_type'] = "image/png"
  response.headers['content_length'] = png_blob.size.to_s
  response.headers['content_disposition'] = "inline" + %(; filename="#{basename}")
  Base64.encode64(png_blob)
end

post '/download_svg' do
  content_type 'image/svg+xml'
  attachment 'syntree.svg'
  rs_generator = RSGenerator.new(params)
  rs_generator.draw_svg
end  

post '/download_pdf' do
  content_type 'applcation/pdf'
  attachment 'syntree.pdf'
  rs_generator = RSGenerator.new(params)
  rs_generator.draw_pdf
end  

