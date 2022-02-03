#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>

$LOAD_PATH << File.join( File.dirname(__FILE__), 'rsyntaxtree')

FONT_DIR = File.expand_path(File.dirname(__FILE__) + "/../fonts")
ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
FONT_SCALING = 2
WHITESPACE_BLOCK = "￭"

class RSTError < StandardError
  def initialize(msg="Error: something unexpected occurred")
    msg.gsub!(WHITESPACE_BLOCK, "<>")
    super msg
  end
end

require 'cgi'
require 'rsvg2'
require 'utils'
require 'element'
require 'elementlist'
require 'string_parser'
require 'svg_graph'
require 'version'
require 'rmagick'

module RSyntaxTree

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

        when :symmetrize, :color, :transparent
          new_params[key] = value && (value != "off" && value != "false") ? true : false
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
        :transparent => false,
        :fontsize    => 16,
        :format      => "png",
        :leafstyle   => "auto",
        :filename    => "syntree",
        :data        => "",
        :margin      => 0,
        :vheight     =>  1.0,
      }

      @params.merge! new_params
      @params[:fontsize]  = @params[:fontsize] * FONT_SCALING
      @params[:margin]    = @params[:margin] * FONT_SCALING
      @params[:fontset] = fontset

      $single_X_metrics = FontMetrics.get_metrics("X", fontset[:normal], @params[:fontsize], :normal, :normal)
      $height_connector_to_text = $single_X_metrics.height / 2.0
      $single_line_height = $single_X_metrics.height * 2.0
      $width_half_X = $single_X_metrics.width / 2.0
      $height_connector = $single_X_metrics.height * 1.0 * @params[:vheight]
      $h_gap_between_nodes = $single_X_metrics.width * 0.8
      $box_vertical_margin = $single_X_metrics.height * 0.8
    end

    def self.check_data(text)
      if text.to_s == ""
        raise RSTError, "Error: input text is empty"
      end
      StringParser.valid?(text)
    end

    def draw_png(binary = false)
      svg = draw_svg
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, dim.width, dim.height)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      b = StringIO.new
      surface.write_to_png(b)
      if binary
        return b
      else
        return b.string
      end
    end

    def draw_svg
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize])
      sp.parse
      graph = SVGGraph.new(sp.get_elementlist, @params)
      graph.svg_data
    end

    def draw_tree
      svg = draw_svg
      image, data = Magick::Image.from_blob(svg) do |im|
        im.format = 'svg'
      end
      if @params[:format] == "png"
        image = draw_png(false)
      else
        image.to_blob do |im|
          im.format = @params[:format].upcase
        end
      end
      image
    end
  end
end

