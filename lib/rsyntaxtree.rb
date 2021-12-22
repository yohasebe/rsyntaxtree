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
# require 'tree_graph'
require 'svg_graph'
require 'error_message'
require 'version'

FONT_DIR = File.expand_path(File.dirname(__FILE__) + "/../fonts")
ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
FONT_SCALING = 2

class RSGenerator
  def initialize(params = {})
    new_params = {}
    fontset = {}
    params.each do |keystr, value|
      key = keystr.to_sym
      case key
      when :data
        data = value
        data  = data.gsub('-AMP-', '&')
          .gsub('-PERCENT-', "%")
          .gsub('-PRIME-', "'")
          .gsub('-SCOLON-', ';')
          .gsub('-OABRACKET-', '<')
          .gsub('-CABRACKET-', '>')
        new_params[key] = data

        # if data.contains_cjk?
        #   new_params[:having_cjk] = true
        # else
        #   new_params[:having_cjk] = false
        # end
        # if data.contains_emoji?
        #   new_params[:having_emoji] = true
        # else
        #   new_params[:having_emoji] = false
        # end

      when :symmetrize, :color, :autosub, :transparent
        new_params[key] = value && value != "off" ? true : false
      when :fontsize
        new_params[key] = value.to_i * FONT_SCALING
      when :margin
        new_params[key] = value.to_i * FONT_SCALING * 5
      when :vheight
        new_params[key] = value.to_f
      when :fontstyle
        if value == "noto-sans" || value == "sans"
          fontset[:normal] = FONT_DIR + "/NotoSans-Regular.ttf"
          fontset[:italic] = FONT_DIR + "/NotoSans-Italic.ttf"
          fontset[:bold] = FONT_DIR + "/NotoSans-Bold.ttf"
          fontset[:bolditalic] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
          fontset[:math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
          fontset[:cjk] = FONT_DIR + "/NotoSansJP-Regular.otf"
          fontset[:emoji] = FONT_DIR + "/OpenMoji-Black.ttf"
          new_params[:fontstyle] = "sans"
        elsif value == "noto-serif" || value == "serif"
          fontset[:normal] = FONT_DIR + "/NotoSerif-Regular.ttf"
          fontset[:italic] = FONT_DIR + "/NotoSerif-Italic.ttf"
          fontset[:bold] = FONT_DIR + "/NotoSerif-Bold.ttf"
          fontset[:bolditalic] = FONT_DIR + "/NotoSerif-BoldItalic.ttf"
          fontset[:math] = FONT_DIR + "/latinmodern-math.otf"
          fontset[:cjk] = FONT_DIR + "/NotoSerifJP-Regular.otf"
          fontset[:emoji] = FONT_DIR + "/OpenMoji-Black.ttf"
          new_params[:fontstyle] = "serif"
        elsif value == "cjk zenhei" || value == "cjk"
          fontset[:normal] = FONT_DIR + "/wqy-zenhei.ttf"
          fontset[:italic] = FONT_DIR + "/NotoSans-Italic.ttf"
          fontset[:bold] = FONT_DIR + "/NotoSans-Bold.ttf"
          fontset[:bolditalic] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
          fontset[:math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
          fontset[:cjk] = FONT_DIR + "/wqy-zenhei.ttf"
          fontset[:emoji] = FONT_DIR + "/OpenMoji-Black.ttf"
          new_params[:fontstyle] = "cjk"
        end
      else
        new_params[key] = value
      end
    end

    # defaults to the following
    @params = {
      :symmetrize  => true,
      :color       => true,
      :autosub     => false,
      :transparent => false,
      :fontsize    => 18,
      :format      => "png",
      :leafstyle   => "auto",
      :filename    => "syntree",
      :data        => "",
      :margin      => 0,
      :vheight     =>  1.0,
      # :fontstyle   => "sans",
      # :font        => "/NotoSansJP-Regular.otf",
      # :font_it     => "/NotoSans-Italic.ttf",
      # :font_bd     => "/NotoSans-Bold.ttf",
      # :font_bdit   => "/NotoSans-BoldItalic.ttf",
      # :font_math   => "/NotoSansMath-Regular.ttf"
    }

    @params.merge! new_params
    @params[:fontsize]  = @params[:fontsize] * FONT_SCALING
    @params[:margin]    = @params[:margin] * FONT_SCALING
    @params[:fontset] = fontset
   end

  def self.check_data(text)
     # sp = StringParser.new(text)
     # sp.valid?
    true
  end

  def draw_png
    svg = draw_svg
    image, data = Magick::Image.from_blob(svg) do |im|
      im.format = 'svg'
    end
    image.to_blob {
      self.format = 'PNG'
    }
  end

  def draw_svg
    sp = StringParser.new(@params[:data].gsub('&', '&amp;').gsub('%', '&#37;'), @params[:fontset], @params[:fontsize])
    sp.parse
    sp.auto_subscript if @params[:autosub]
    elist = sp.get_elementlist
    graph = SVGGraph.new(elist,
      @params[:symmetrize], @params[:color], @params[:leafstyle], @params[:fontstyle], @params[:fontset], @params[:fontsize], @params[:margin], @params[:transparent],
      @params[:vheight]
    )
    graph.svg_data
  end

  def draw_tree
    svg = draw_svg
    image, data = Magick::Image.from_blob(svg) do |im|
      im.format = 'svg'
    end
    image.to_blob do |im|
      im.format = @params[:format].upcase
    end
    image
  end
end

