#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
# Copyright (c) 2007-2009 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

$LOAD_PATH << File.join( File.dirname(__FILE__), 'rsyntaxtree')
$LOAD_PATH << File.join( File.dirname(__FILE__), '../helpers')

require 'uri'
require 'imgutils'
require 'element'
require 'elementlist'
require 'string_parser'
require 'tree_graph'
require 'svg_graph'
require 'error_message'
require 'helpers'
require 'version'

FONT_DIR = File.expand_path(File.dirname(__FILE__) + "/../fonts")

class RSGenerator 
  include Helpers
  def initialize(params = {})
    new_params = {}
    params.each do |key, value|
      case key
      when "data"
        data = URI.unescape(value)
        data  = data.gsub('-AMP-', '&').gsub('-PRIME-', "'").gsub('-SCOLON-', ';')
        new_params[key] = data
      when "symmetrize", "color", "autosub"
        new_params[key] = value == "on"? true : false
      when "fontsize"
        new_params[key] = value.to_i
      when "fontstyle"
        if value == "sans-serif"
          new_params["font"] = FONT_DIR + "/DroidSans.ttf"
        elsif value == "serif"
          new_params["font"] = FONT_DIR + "/DroidSerif-Regular.ttf"
        elsif value == "jp-gothic"
          new_params["font"] = FONT_DIR + "/ipagp.ttf"
        elsif value == "jp-mincho"
          new_params["font"] = FONT_DIR + "/ipamp.ttf"
        elsif value == "cjk"
          new_params["font"] = FONT_DIR + "/wqy-zenhei.ttf"
        elsif value == "aru"
          new_params["font"] = FONT_DIR + "/ArialUnicode.ttf"
        elsif value == "tnr"
          new_params["font"] = FONT_DIR + "/TimesNewRoman.ttf"
        elsif value == "noto"
          new_params["font"] = FONT_DIR + "/NotoSansCJK.ttc"
        end
      else
        new_params[key] = value
      end
    end
    
    
    @params = {
      "symmetrize" => true,
      "color"      => true,
      "autosub"    => false,
      "fontsize"   => 18,
      "format"     => "png",
      "leafstyle"   => "auto",
      "font"        => FONT_DIR + "/ipagp.ttf",
      "filename"   => "syntree",
      "data"       => "",
    }
    
    @params.merge! new_params
   end

  def self.check_data(text)
     # StringParser.validate_text(text)     
     sp = StringParser.new(text)
     sp.valid?
  end
  
  def draw_png
    @params["format"] = "png"
    draw_tree
  end

  def draw_pdf
    @params["format"] = "pdf"
    draw_tree
  end
    
  def draw_tree
    sp = StringParser.new(@params["data"])
    sp.parse
    sp.auto_subscript if @params["autosub"]
    elist = sp.get_elementlist
    graph = TreeGraph.new(elist, 
      @params["symmetrize"], @params["color"], @params["leafstyle"], @params["font"], @params["fontsize"], @params["format"])
    graph.to_blob(@params["format"])
  end
  
  def draw_svg
    @params["format"] = "svg"
    sp = StringParser.new(@params["data"].gsub('&', '&amp;'))
    sp.parse
    sp.auto_subscript if @params["autosub"]
    elist = sp.get_elementlist
    graph = SVGGraph.new(elist, 
      @params["symmetrize"], @params["color"], @params["leafstyle"], @params["font"], @params["fontsize"])
    graph.svg_data
  end
end

