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
# Copyright (c) 2007-2018 Yoichiro Hasebe <yohasebe@gmail.com>
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

require 'uri'
require 'imgutils'
require 'element'
require 'elementlist'
require 'string_parser'
require 'tree_graph'
require 'svg_graph'
require 'error_message'
require 'version'
require 'pp'

FONT_DIR = File.expand_path(File.dirname(__FILE__) + "/../fonts")

ETYPE_UNDEFINED = 0
ETYPE_NODE = 1
ETYPE_LEAF = 2

class RSGenerator 
  def initialize(params = {})
    new_params = {}
    params.each do |keystr, value|
      key = keystr.to_sym
      case key
      when :data
        data = URI.unescape(value)
        data  = data.gsub('-AMP-', '&')
          .gsub('-PERCENT-', "%")
          .gsub('-PRIME-', "'")
          .gsub('-SCOLON-', ';')
          .gsub('-OABRACKET-', '<')
          .gsub('-CABRACKET-', '>')
        new_params[key] = data
      when :symmetrize, :color, :autosub
        new_params[key] = value && value != "off" ? true : false
      when :fontsize
        new_params[key] = value.to_i
      when :margin
        new_params[key] = value.to_i
      when :vheight
        new_params[key] = value.to_f
      when :fontstyle
        if value == "noto-sans" || value == "sans"
          new_params[:font] = FONT_DIR + "/NotoSansCJKjp-Regular.otf"
        elsif value == "noto-serif" || value == "serif"
          new_params[:font] = FONT_DIR + "/NotoSerifCJKjp-Regular.otf"
        elsif value == "noto-mono" || value == "mono"
          new_params[:font] = FONT_DIR + "/NotoSansMonoCJKjp-Regular.otf"
        elsif value == "western-sans"
          new_params[:font] = FONT_DIR + "/DroidSans.ttf"
        elsif value == "western-serif"
          new_params[:font] = FONT_DIR + "/DroidSerif-Regular.ttf"
        elsif value == "cjk zenhei" || value == "cjk"
          new_params[:font] = FONT_DIR + "/wqy-zenhei.ttf"
        end
      else
        new_params[key] = value
      end
    end
    
    @params = {
      :symmetrize => true,
      :color      => true,
      :autosub    => false,
      :fontsize   => 18,
      :format     => "png",
      :leafstyle  => "auto",
      :font       => FONT_DIR + "/NotoSansCKjp-Regular.otf",
      :filename   => "syntree",
      :data       => "",
      :margin     => 0,
      :vheight     =>  1.0
    }
    @metrics = {
      :e_width  => 120,
      :e_padd   => 14,
      :v_space  => 20,
      :h_space  => 20,
      :b_side   => 10,
      :b_topbot => 10
    }
    
    @params.merge! new_params
    @params[:fontsize]  = @params[:fontsize] * 2
    @params[:margin]    = @params[:margin] * 2
    @metrics[:v_space] = @metrics[:v_space] * @params[:vheight]
   end

  def self.check_data(text)
     sp = StringParser.new(text)
     sp.valid?
  end
  
  def draw_png
    @params[:format] = "png"
    draw_tree
  end

  def draw_jpg
    @params[:format] = "jpg"
    draw_tree
  end

  def draw_gif
    @params[:format] = "gif"
    draw_tree
  end

  def draw_pdf
    @params[:format] = "pdf"
    draw_tree
  end
    
  def draw_tree
    sp = StringParser.new(@params[:data])
    sp.parse
    sp.auto_subscript if @params[:autosub]
    elist = sp.get_elementlist
    graph = TreeGraph.new(elist, @metrics,
      @params[:symmetrize], @params[:color], @params[:leafstyle], @params[:font], @params[:fontsize], @params[:format], @params[:margin])
    graph.to_blob(@params[:format])
  end
  
  def draw_svg
    @params[:format] = "svg"
    sp = StringParser.new(@params[:data].gsub('&', '&amp;').gsub('%', '&#37;'))
    sp.parse
    sp.auto_subscript if @params[:autosub]
    elist = sp.get_elementlist
    graph = SVGGraph.new(elist, @metrics,
      @params[:symmetrize], @params[:color], @params[:leafstyle], @params[:font], @params[:fontsize])
    graph.svg_data
  end
end

