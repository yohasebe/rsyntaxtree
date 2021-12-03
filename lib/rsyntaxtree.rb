#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
#
# This file is part of RSyntaxTree, which is originally a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

$LOAD_PATH << File.join( File.dirname(__FILE__), 'rsyntaxtree')

require 'cgi'
require 'utils'
require 'element'
require 'elementlist'
require 'string_parser'
require 'tree_graph'
require 'svg_graph'
require 'error_message'
require 'version'

FONT_DIR = File.expand_path(File.dirname(__FILE__) + "/../fonts")

ETYPE_UNDEFINED = 0
ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
FONT_SCALING = 2

class RSGenerator
  def initialize(params = {})
    new_params = {}
    params.each do |keystr, value|
      key = keystr.to_sym
      case key
      when :data
        data = CGI.unescape(value)
        data  = data.gsub('-AMP-', '&')
          .gsub('-PERCENT-', "%")
          .gsub('-PRIME-', "'")
          .gsub('-SCOLON-', ';')
          .gsub('-OABRACKET-', '<')
          .gsub('-CABRACKET-', '>')
        new_params[key] = data
        new_params[:multibyte] = data.contains_cjk?
      when :symmetrize, :color, :autosub
        new_params[key] = value && value != "off" ? true : false
      when :fontsize
        new_params[key] = value.to_i * FONT_SCALING
      when :margin
        new_params[key] = value.to_i * FONT_SCALING * 4
      when :vheight
        new_params[key] = value.to_f
      when :fontstyle
        if value == "noto-sans" || value == "sans"
          new_params[:font] = FONT_DIR + "/NotoSans-Regular.ttf"
          new_params[:font_it] = FONT_DIR + "/NotoSans-Italic.ttf"
          new_params[:font_bd] = FONT_DIR + "/NotoSans-Bold.ttf"
          new_params[:font_bdit] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
          new_params[:font_math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
          new_params[:font_cjk] = FONT_DIR + "/NotoSansCJKjp-Regular.otf"
          new_params[:fontstyle] = "sans"
        elsif value == "noto-serif" || value == "serif"
          new_params[:font] = FONT_DIR + "/NotoSerif-Regular.ttf"
          new_params[:font_it] = FONT_DIR + "/NotoSerif-Italic.ttf"
          new_params[:font_bd] = FONT_DIR + "/NotoSerif-Bold.ttf"
          new_params[:font_bdit] = FONT_DIR + "/NotoSerif-BoldItalic.ttf"
          new_params[:font_math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
          new_params[:font_cjk] = FONT_DIR + "/NotoSerifCJKjp-Regular.otf"
          new_params[:fontstyle] = "serif"
        elsif value == "cjk zenhei" || value == "cjk"
          new_params[:font] = FONT_DIR + "/wqy-zenhei.ttf"
          new_params[:font_it] = FONT_DIR + "/NotoSans-Italic.ttf"
          new_params[:font_bd] = FONT_DIR + "/NotoSans-Bold.ttf"
          new_params[:font_bdit] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
          new_params[:font_math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
          new_params[:font_cjk] = FONT_DIR + "/wqy-zenhei.ttf"
          new_params[:fontstyle] = "sans"
        elsif value == "modern-math" || value == "math"
          new_params[:font] = FONT_DIR + "/latinmodern-math.otf"
          new_params[:font_it] = FONT_DIR + "/lmroman10-italic.otf"
          new_params[:font_bd] = FONT_DIR + "/lmroman10-bold.otf"
          new_params[:font_bdit] = FONT_DIR + "/lmroman10-bolditalic.otf"
          new_params[:font_math] = FONT_DIR + "/latinmodern-math.otf"
          new_params[:font_cjk] = FONT_DIR + "/NotoSerifCJKjp-Regular.otf"
          new_params[:fontstyle] = "math"
        end
      else
        new_params[key] = value
      end
    end

    # defaults to the following
    @params = {
      :symmetrize => true,
      :color      => true,
      :autosub    => false,
      :fontsize   => 18,
      :format     => "png",
      :leafstyle  => "auto",
      :filename   => "syntree",
      :data       => "",
      :margin     => 0,
      :vheight    =>  1.0,
      :fontstyle  => "sans",
      :font       => "/NotoSansCJKjp-Regular.otf",
      :font_it    => "/NotoSans-Italic.ttf",
      :font_bd    => "/NotoSans-Bold.ttf",
      :font_bdit  => "/NotoSans-BoldItalic.ttf",
      :font_math  => "/NotoSansMath-Regular.ttf"
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
    @params[:fontsize]  = @params[:fontsize] * FONT_SCALING
    @params[:margin]    = @params[:margin] * FONT_SCALING
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

  def draw_svg
    @params[:format] = "svg"
    sp = StringParser.new(@params[:data].gsub('&', '&amp;').gsub('%', '&#37;'))
    sp.parse
    sp.auto_subscript if @params[:autosub]
    elist = sp.get_elementlist
    graph = SVGGraph.new(elist, @metrics,
      @params[:symmetrize], @params[:color], @params[:leafstyle], @params[:multibyte],
      @params[:fontstyle], @params[:font], @params[:font_cjk], @params[:fontsize], @params[:margin]
    )
    graph.svg_data
  end

  def draw_tree
    sp = StringParser.new(@params[:data])
    sp.parse
    sp.auto_subscript if @params[:autosub]
    elist = sp.get_elementlist
    graph = TreeGraph.new(elist, @metrics,
      @params[:symmetrize], @params[:color], @params[:leafstyle], @params[:multibyte],
      @params[:fontstyle], @params[:font], @params[:font_it], @params[:font_bd], @params[:font_bdit], @params[:font_math],
      @params[:font_cjk], @params[:fontsize], @params[:margin],
    )
    graph.to_blob(@params[:format])
  end
end

