# frozen_string_literal: true

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
# Copyright (c) 2007-2024 Yoichiro Hasebe <yohasebe@gmail.com>

FONT_DIR = File.expand_path(File.join(__dir__, "/../fonts"))
ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
FONT_SCALING = 2
LINE_SCALING = 1
BLINE_SCALING = 2
WHITESPACE_BLOCK = "￭"
DEFAULT_OPTS = {
  format: "png",
  leafstyle: "auto",
  fontstyle: "sans",
  fontsize: 16,
  linewidth: 1,
  vheight: 2.0,
  color: "modern",
  symmetrize: "on",
  transparent: "off",
  polyline: "off",
  hide_default_connectors: "off"
}.freeze

class RSTError < StandardError
  def initialize(msg = "Error: something unexpected occurred")
    msg.gsub!(WHITESPACE_BLOCK, "<>")
    super msg
  end
end

require_relative 'rsyntaxtree/utils'
require_relative 'rsyntaxtree/element'
require_relative 'rsyntaxtree/elementlist'
require_relative 'rsyntaxtree/svg_graph'
require_relative 'rsyntaxtree/version'
require_relative 'rsyntaxtree/string_parser'

require 'cgi'
require 'rsvg2'
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
          data = data.gsub('-AMP-', '&')
                     .gsub('-PERCENT-', "%")
                     .gsub('-PRIME-', "'")
                     .gsub('-SCOLON-', ';')
                     .gsub('-OABRACKET-', '<')
                     .gsub('-CABRACKET-', '>')
                     .gsub('¥¥', '\¥')
                     .gsub(/(?<!\\)¥/, "\\")
                     .gsub(/\\\[/, "［")
                     .gsub(/\\\]/, "］")
          new_params[key] = data

        when :symmetrize, :transparent, :polyline, :hide_default_connectors
          new_params[key] = value && (value != "off" && value != "false") ? true : false
        when :color
          new_params[key] = case value
                            when "modern", "on", "true"
                              "modern"
                            when "traditional"
                              "traditional"
                            else
                              "off"
                            end
        when :fontsize
          new_params[key] = value.to_i
        when :linewidth
          new_params[key] = value.to_i
        when :vheight
          new_params[key] = value.to_f
        when :fontstyle
          case value
          when "noto-sans-mono", "mono"
            fontset[:normal] = FONT_DIR + "/NotoSansMono_SemiCondensed-Regular.ttf"
            fontset[:italic] = FONT_DIR + "/NotoSansMono_SemiCondensed-Regular.ttf"
            fontset[:bold] = FONT_DIR + "/NotoSansMono_SemiCondensed-Bold.ttf"
            fontset[:bolditalic] = FONT_DIR + "/NotoSansMono_SemiCondensed-Bold.ttf"
            fontset[:math] = FONT_DIR + "/latinmodern-math.otf"
            fontset[:cjk] = FONT_DIR + "/NotoSansJP-Regular.otf"
            fontset[:emoji] = FONT_DIR + "/OpenMoji-black-glyf.ttf"
            new_params[:fontstyle] = "mono"
          when "noto-sans", "sans"
            fontset[:normal] = FONT_DIR + "/NotoSans-Regular.ttf"
            fontset[:italic] = FONT_DIR + "/NotoSans-Italic.ttf"
            fontset[:bold] = FONT_DIR + "/NotoSans-Bold.ttf"
            fontset[:bolditalic] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
            fontset[:math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
            fontset[:cjk] = FONT_DIR + "/NotoSansJP-Regular.otf"
            fontset[:emoji] = FONT_DIR + "/OpenMoji-black-glyf.ttf"
            new_params[:fontstyle] = "sans"
          when "noto-serif", "serif"
            fontset[:normal] = FONT_DIR + "/NotoSerif-Regular.ttf"
            fontset[:italic] = FONT_DIR + "/NotoSerif-Italic.ttf"
            fontset[:bold] = FONT_DIR + "/NotoSerif-Bold.ttf"
            fontset[:bolditalic] = FONT_DIR + "/NotoSerif-BoldItalic.ttf"
            fontset[:math] = FONT_DIR + "/latinmodern-math.otf"
            fontset[:cjk] = FONT_DIR + "/NotoSerifJP-Regular.otf"
            fontset[:emoji] = FONT_DIR + "/OpenMoji-black-glyf.ttf"
            new_params[:fontstyle] = "serif"
          when "cjk zenhei", "cjk"
            fontset[:normal] = FONT_DIR + "/wqy-zenhei.ttf"
            fontset[:italic] = FONT_DIR + "/NotoSans-Italic.ttf"
            fontset[:bold] = FONT_DIR + "/NotoSans-Bold.ttf"
            fontset[:bolditalic] = FONT_DIR + "/NotoSans-BoldItalic.ttf"
            fontset[:math] = FONT_DIR + "/NotoSansMath-Regular.ttf"
            fontset[:cjk] = FONT_DIR + "/wqy-zenhei.ttf"
            fontset[:emoji] = FONT_DIR + "/OpenMoji-black-glyf.ttf"
            new_params[:fontstyle] = "cjk"
          end
        else
          new_params[key] = value
        end
      end

      # defaults to the following
      @params = DEFAULT_OPTS.dup
      @params.merge! new_params
      @params[:fontsize] = @params[:fontsize] * FONT_SCALING
      @params[:fontset] = fontset
      single_x_metrics = FontMetrics.get_metrics("X", fontset[:normal], @params[:fontsize], :normal, :normal)
      @global = {}
      @global[:single_x_metrics] = single_x_metrics
      @global[:height_connector_to_text] = single_x_metrics.height / 2.0
      @global[:single_line_height] = single_x_metrics.height * 2.0
      @global[:width_half_x] = single_x_metrics.width / 2.0
      @global[:height_connector] = single_x_metrics.height * @params[:vheight]
      @global[:h_gap_between_nodes] = single_x_metrics.width * 0.8
      @global[:box_vertical_margin] = single_x_metrics.height * 0.8
    end

    def self.check_data(text)
      raise RSTError, +"Error: input text is empty" if text.to_s == ""

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
        b
      else
        b.string
      end
    rescue Cairo::InvalidSize
      raise RSTError, +"Error: the result syntree is too big"
    end

    def draw_pdf(binary = false)
      b = StringIO.new
      svg = draw_svg
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::PDFSurface.new(b, dim.width, dim.height)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      surface.finish
      if binary
        b
      else
        b.string
      end
    rescue Cairo::InvalidSize
      raise RSTError, +"Error: the result syntree is too big"
    end

    def draw_svg
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      graph = SVGGraph.new(sp.get_elementlist, @params, @global)
      graph.svg_data
    end

    # Currently not used
    def draw_tree
      svg = draw_svg
      image, _data = Magick::Image.from_blob(svg) do |im|
        im.format = 'svg'
      end
      image.to_blob do |im|
        im.format = @params[:format].upcase
      end
      image
    end
  end
end
