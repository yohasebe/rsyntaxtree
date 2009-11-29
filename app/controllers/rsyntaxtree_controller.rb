#==========================
# rsyntaxtree_controller.rb
#==========================
#
# Controller of Rails interface to RSyntaxTree
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
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

require "rsyntaxtree"
require 'cgi'
require 'rubygems'
require 'RMagick'
include Magick

class RsyntaxtreeController < ApplicationController

  def index
   render :layout => false
  end

  def build_query

    if !params[:data] || params[:data] == ""
      render(:text => "There is no text to parse")

    elsif params[:data].length > 512
        @error = "Sorry, the input data is too large..."
        render(:partial => 'error')
    else
      format     = params[:format]
      symmetrize =params[:symmetrize]
      color      = params[:color]
      terminal   = params[:terminal]
      autosub    = params[:autosub]
      serif      = params[:serif]
      fontsize   = params[:fontsize]
      new_data1  = CGI::escapeHTML(params[:data])
      new_data2  = new_data1.gsub(/'/, "-PRIME-")
      text =<<EOD
<div id='phrase'>#{new_data1}</div>
<div id='graph'>
<img src='/rsyntaxtree/rsyntaxtree/draw_graph?data=#{new_data2}&format=#{format}&symmetrize=#{symmetrize}&color=#{color}&terminal=#{terminal}&autosub=#{autosub}&serif=#{serif}&fontsize=#{fontsize}' alt='#{new_data2}'/>
<br /><br />
<small>
<a href='/rsyntaxtree/rsyntaxtree/draw_graph?data=#{new_data2}&format=svg&symmetrize=#{symmetrize}&color=#{color}&terminal=#{terminal}&autosub=#{autosub}&serif=#{serif}&fontsize=#{fontsize}'>[Download SVG]</a>
</small>
</div>
EOD
      render(:text => text)
    end

  end

  def draw_graph

      symmetrize = params[:symmetrize] == "on" ? true : false
      color      = params[:color]      == "on" ? true : false
      autosub    = params[:autosub]    == "on" ? true : false
      with_serif = params[:serif]      == "on" ? true : false
      fontsize   = params[:fontsize].to_i
      data       = params[:data].gsub(/-PRIME-/, "'")
      format     = params[:format].strip
      terminal   = params[:terminal].strip
      filename   = "syntree"

      font_serif      = File.expand_path("#{RAILS_ROOT}/fonts/vera/VeraSe.ttf")
      font_nonserif   = File.expand_path("#{RAILS_ROOT}/fonts/vera/Vera.ttf")
      font_mbserif    = File.expand_path("#{RAILS_ROOT}/fonts/ipa/ipamp.ttf")
      font_mbnonserif = File.expand_path("#{RAILS_ROOT}/fonts/ipa/ipagp.ttf")
      font_mbnonja    = File.expand_path("#{RAILS_ROOT}/fonts/wqy-zenhei/wqy-zenhei.ttf")

      if multibyte?(data)
        if japanese?(data) || !File.exist?(font_mbnonja)
          if with_serif   
            font = font_mbserif
          else
            font = font_mbnonserif
          end
        else
          font = font_mbnonja
        end
      else
        if with_serif
          font = font_serif
        else
          font = font_nonserif
        end
      end

      sp = StringParser.new(CGI.unescapeHTML(data))
      if(!sp.validate)
        e_message = "Error: problem in input sentence"
        sp = StringParser.new(e_message)
        sp.parse
        elist =sp.get_elementlist
        graph = TreeGraph.new(elist, true, false, false, font_nonserif, 14)
        image_data = graph.to_blob
        send_data( image_data,
                   :disposition=> 'inline',
                   :type => 'image/png',
                   :filename => "error.png")
      else
        sp.parse
        sp.auto_subscript if autosub
        elist = sp.get_elementlist

        case format
        when /svg/
          engine = SVGGraph
        when /(gif|jpg|bmp)/
          engine = TreeGraph
        else
          engine = TreeGraph
          format = "png"
        end
        graph = engine.new(elist, symmetrize, color, terminal, font, fontsize)
        if format == "svg"
          send_data(graph.svg_data,
                    :filename => 'synatxtree.svg')
        else
          image_data = graph.to_blob(format)
          graph.destroy
          send_data( image_data,
                     :disposition=> "inline",
                     :type => "image/#{format}",
                     :filename => "syntaxtree.#{format}")
          graph.destroy
        end
      end
      GC.start
    end

    def multibyte?(text)
      result = false
      text.strip.split(//).each do |chr|
        unless /([!-~]|\s)/ =~ chr
          result = true; break
        end
      end
      return result
    end

    def japanese?(text) #check if text contains hiragana or katakana
      result = false
      text.strip.split(//).each do |chr|
        if /(\xe3(\x82[\xa1-\xbf]|\x83[\x80-\xbf]))/ =~ chr ||
           /(\xe3(\x81[\x80-\xbf]|\x82[\x80-\xa0]))/ =~ chr
           #|| /[一-龠]+/ =~ chr
          result = true; break
        end
      end
      return result
    end

    def count_brackets
      text = params['text'].strip
      text_r = text.split(//)
      open_br, close_br = [], []
      text_r.each do |chr|
        if chr == '['
          open_br.push(chr)
        elsif chr == ']'
          close_br.push(chr)
          if open_br.length < close_br.length
            break
          end
        end
      end

      if open_br.length == close_br.length
        message = "&nbsp;"
      else
        message = "Open and close brackets do not match up."
      end

      render(:text => message)
    end

end
