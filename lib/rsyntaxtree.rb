# frozen_string_literal: true

#==========================
# rsyntaxtree.rb
#==========================
#
# Facade of rsyntaxtree library.  When loaded by a driver script, it does all
# the necessary 'require' to use the library.
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

ETYPE_NODE = 1
ETYPE_LEAF = 2
SUBSCRIPT_CONST = 0.7
# A box or circle is drawn at this size — a fraction of the font size —
# whatever it encloses, so that hatched, empty and lettered shapes in one
# figure share a diameter. It only grows for content that would not fit:
# see ENCLOSURE_PADDING and Element#setup.
ENCLOSURE_SIZE = 1.3
# Breathing room kept between the marks and a shape that had to grow past
# ENCLOSURE_SIZE, as a fraction of the font size.
ENCLOSURE_PADDING = 0.12
# Room on each side of a matrix nested in a label, as a multiple of half an
# 'X'. It sets the distance between a matrix and its own brackets, and so also
# the distance between the brackets of adjacent or nested matrices — the
# closing brackets of a deep feature path stack up otherwise.
MATRIX_BRACKET_ROOM = 2.5
# Room above and below a matrix nested in a label, as a fraction of the line
# height. Without it a bracketed value sits hard against the rows either side
# of it, since the rows are spaced for text rather than for a block.
MATRIX_VERTICAL_ROOM = 0.25
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
  symmetrize: "off",
  transparent: "off",
  polyline: "off",
  hide_default_connectors: "off",
  mirror: "off",
  tidy: "off",
  hspacing: 1.0,
  direction: "ttb",
  hyphen: "markup"
}.freeze

class RSTError < StandardError
  def initialize(msg = "Error: something unexpected occurred")
    # Non-destructive: every file here carries frozen_string_literal, so
    # mutating the message in place turned a raise with a plain literal into
    # a FrozenError from inside the error class itself.
    super(msg.gsub(WHITESPACE_BLOCK, "<>"))
  end
end

require_relative 'rsyntaxtree/utils'
require_relative 'rsyntaxtree/element'
require_relative 'rsyntaxtree/elementlist'
require_relative 'rsyntaxtree/svg_graph'
require_relative 'rsyntaxtree/lsif_graph'
require_relative 'rsyntaxtree/tikz_generator'
require_relative 'rsyntaxtree/version'
require_relative 'rsyntaxtree/string_parser'

require 'cgi'
require 'rsvg2'

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
          new_params[key] = data

        when :tidy
          # One layout scale from the most spacious to the most dense:
          # "symmetric" (radical symmetrization, uniform sibling slots),
          # "off" (the traditional layout), "low" (contour packing with
          # strict leaf positions), "medium" (packing that may tuck
          # branches across rows as long as no two leaves swap their
          # left-right order), "high" (free tucking; leaf order kept per
          # row only). "on"/"compact" are accepted as legacy aliases of
          # low/high, legacy tidy_nest: "on" upgrades low to high, and
          # legacy symmetrize: "on" upgrades "off" to "symmetric" (both
          # below, in BaseGraph).
          new_params[key] = case value.to_s
                            when "high", "compact"
                              "high"
                            when "medium"
                              "medium"
                            when "low", "on", "true"
                              "low"
                            when "symmetric"
                              "symmetric"
                            else
                              "off"
                            end
        when :tidy_nest
          new_params[key] = value && (value != "off" && value != "false") ? true : false
        when :symmetrize, :transparent, :polyline, :hide_default_connectors, :mirror
          new_params[key] = value && (value != "off" && value != "false") ? true : false
        when :color
          new_params[key] = case value
                            when "modern", "on", "true"
                              "modern"
                            when "traditional"
                              "traditional"
                            when "gray", "grey"
                              "gray"
                            else
                              "off"
                            end
        when :hyphen
          new_params[key] = value.to_s == "literal" ? "literal" : "markup"
        when :fontsize
          new_params[key] = value.to_i
        when :linewidth
          new_params[key] = value.to_i
        when :vheight, :hspacing, :tidy_spacing
          new_params[key] = value.to_f
        when :fontstyle
          # Fonts are resolved by name through fontconfig (measurement via
          # Pango, rendering via the SVG font-family attribute), so all a
          # style needs is its family fallback chain.
          style = case value
                  when "noto-sans-mono", "mono" then :mono
                  when "noto-serif", "serif" then :serif
                  when "cjk zenhei", "cjk" then :cjk
                  else :sans
                  end
          fontset[:family] = FontFamily.for_pango(style)
          fontset[:family_cjk] = FontFamily.for_pango(style, cjk_priority: style != :cjk)
          new_params[:fontstyle] = style.to_s
        else
          new_params[key] = value
        end
      end

      # Legacy alias: tidy_spacing was the tidy-only horizontal gap factor
      # before it was generalized to hspacing (all layout modes).
      if (new_params[:hspacing].nil? || new_params[:hspacing] == 1.0) &&
         new_params[:tidy_spacing] && new_params[:tidy_spacing] != 1.0
        new_params[:hspacing] = new_params[:tidy_spacing]
      end

      # defaults to the following
      @params = DEFAULT_OPTS.dup
      @params.merge! new_params
      @params[:fontsize] = @params[:fontsize] * FONT_SCALING
      # fontset is populated above only when :fontstyle is passed explicitly;
      # fall back to the merged default style otherwise
      if fontset[:family].nil?
        fontset[:family] = FontFamily.for_pango(@params[:fontstyle])
        fontset[:family_cjk] = FontFamily.for_pango(@params[:fontstyle], cjk_priority: true)
      end
      @params[:fontset] = fontset
      single_x_metrics = FontMetrics.get_metrics("X", fontset[:family], @params[:fontsize], :normal, :normal)
      @global = {}
      @global[:single_x_metrics] = single_x_metrics
      @global[:height_connector_to_text] = single_x_metrics.height / 2.0
      @global[:single_line_height] = single_x_metrics.height * 2.0
      @global[:width_half_x] = single_x_metrics.width / 2.0
      @global[:height_connector] = single_x_metrics.height * @params[:vheight]
      # Horizontal counterpart of vheight: hspacing scales every horizontal
      # gap (sibling clearance in all layout modes, tidy minimum gap,
      # margins) the way vheight scales the vertical rhythm.
      @global[:h_gap_between_nodes] = single_x_metrics.width * 0.8 * (@params[:hspacing] || 1.0).to_f
      @global[:box_vertical_margin] = single_x_metrics.height * 0.8
      # hyphen: literal swaps the two readings of - when a label is parsed.
      @global[:literal_hyphen] = @params[:hyphen] == "literal"
    end

    # Two gates, because neither one alone tells the truth.
    #
    # Bracket balance catches what the drawing path silently repairs: it
    # closes an unclosed bracket and drops a stray one, so a typo would
    # otherwise draw a tree the writer never asked for.
    #
    # Parsing catches what balance cannot see: label markup — an unpaired
    # underline in a word, a matrix left open where a raw space split a
    # value — passes the bracket count and then fails at draw time, which
    # is how a caller came to be told "OK" and still get an error.
    #
    # Passing both means the input is well-formed and really does draw.
    #
    # Options matter to the second gate: `hyphen: "literal"` decides whether
    # a hyphen is an underline, so validating without the caller's options
    # rejects input that draws.
    def self.check_data(text, params = {})
      raise RSTError, +"Error: input text is empty" if text.to_s == ""

      StringParser.valid?(text)
      new(params.merge(data: text)).validate!
    end

    def validate!
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      true
    end

    def draw_png(binary = false)
      surface = nil
      context = nil
      b = nil
      svg = draw_svg
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, dim.width, dim.height)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      b = StringIO.new
      surface.write_to_png(b)
      binary ? b : b.string
    rescue Cairo::InvalidSize
      raise RSTError, +"Error: the result syntree is too big"
    ensure
      b&.close unless binary
      surface&.finish
      context&.destroy
    end

    def draw_pdf(binary = false)
      surface = nil
      context = nil
      b = nil
      b = StringIO.new
      svg = draw_svg
      rsvg = RSVG::Handle.new_from_data(svg)
      dim = rsvg.dimensions
      surface = Cairo::PDFSurface.new(b, dim.width, dim.height)
      context = Cairo::Context.new(surface)
      context.render_rsvg_handle(rsvg)
      surface.finish
      binary ? b : b.string
    rescue Cairo::InvalidSize
      raise RSTError, +"Error: the result syntree is too big"
    ensure
      b&.close unless binary
      context&.destroy
    end

    def draw_svg
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      graph = SVGGraph.new(sp.get_elementlist, @params, @global)
      graph.svg_data
    end

    # JPG and GIF output converts the PNG through RMagick. The require is
    # lazy: both formats are deprecated and will be removed in 2.0, and the
    # library must load without RMagick for every other format. A missing
    # RMagick is reported as an input-level error, not a bare LoadError.
    def with_rmagick
      require 'rmagick'
      yield
    rescue LoadError
      raise RSTError, +"Error: JPG/GIF output requires ImageMagick and the rmagick gem, " \
                      "which is not installed. Use PNG instead — JPG and GIF support " \
                      "is deprecated and will be removed in 2.0."
    end

    def draw_jpg
      with_rmagick do
        png_data = draw_png
        images = Magick::Image.from_blob(png_data)
        image = images.first
        image.format = 'JPEG'
        blob = image.to_blob
        images.each(&:destroy!)
        blob
      end
    end

    def draw_gif
      with_rmagick do
        png_data = draw_png
        images = Magick::Image.from_blob(png_data)
        image = images.first
        image.format = 'GIF'
        blob = image.to_blob
        images.each(&:destroy!)
        blob
      end
    end

    def draw_lsif
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      graph = LsifGraph.new(sp.get_elementlist, @params, @global)
      graph.lsif_data
    end

    def draw_tikz(standalone: false, font: nil)
      sp = StringParser.new(@params[:data].gsub('&', '&amp;'), @params[:fontset], @params[:fontsize], @global)
      sp.parse
      generator = TikZGenerator.new(sp.get_elementlist, @params)
      generator.generate(standalone: standalone, font: font)
    end
  end
end
