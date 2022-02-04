#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# string_parser.rb
#==========================
#
# Parses a phrase into leafs and nodes and store the result in an element list
# (see element_list.rb)
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>

require 'elementlist'
require 'element'
require 'utils'

module RSyntaxTree
  class StringParser

    attr_accessor :data, :elist, :pos, :id, :level
    def initialize(str, fontset, fontsize)
      # Clean up the data a little to make processing easier
      # repeated newlines => a newline
      string = str.gsub(/[\n\r]+/m, "\n")
      # a backslash followed by a newline => a backslash followed by an 'n'
      string.gsub!(/\\\n\s*/m, "\\n")
      # repeated whitespace characters => " "
      string.gsub!(/\s+/, " ")
      string.gsub!(/\]\s+\[/, "][")
      string.gsub!(/\s+\[/, "[")
      string.gsub!(/\[\s+/, "[")
      string.gsub!(/\s+\]/, "]")
      string.gsub!(/\]\s+/, "]")
      string.gsub!(/<(\d*)>/) do
        num_padding = $1.to_i
        if num_padding > 0
          result = WHITESPACE_BLOCK * num_padding
        else
          result = WHITESPACE_BLOCK
        end
        result
      end

      @data = string # Store it for later...
      if @data.contains_cjk?
        fontset[:normal] = fontset[:cjk]
      end
      @elist = ElementList.new # Initialize internal element list
      @pos = 0 # Position in the sentence
      @id = 1 # ID for the next element
      @level = 0 # Level in the diagram
      @fontset = fontset
      @fontsize = fontsize
    end

    def self.valid?(data)
      if(data.length < 1)
        raise RSTError, "Error: input text is empty"
      end

      if /\[\s*\]/m =~ data
        raise RSTError, "Error: inside the brackets is empty"
      end

      text = data.strip
      text_r = text.split(//)
      open_br, close_br = [], []
      escape = false
      text_r.each do |chr|
        if chr == "\\"
          if escape
            escape = false
          else
            escape = true
          end
          next
        end

        if escape && /[\[\]]/ =~ chr
          escape = false
          next
        elsif chr == '['
          open_br.push(chr)
        elsif chr == ']'
          close_br.push(chr)
          if open_br.length < close_br.length
            break
          end
        end
        escape = false
      end

      if open_br.empty? && close_br.empty?
        raise RSTError, "Error: input text does not contain paired brackets"
      elsif open_br.length == close_br.length
        return true
      else
        raise RSTError, "Error: open and close brackets do not match"
      end
    end

    def parse
      make_tree(0);
      @elist.set_hierarchy
    end

    def get_elementlist
      @elist;
    end

    def get_next_token
      data = @data.split(//)
      gottoken = false
      token = ""
      i = 0

      if((@pos + 1) >= data.length)
        return ""
      end

      escape = false
      while(((@pos + i) < data.length) && !gottoken)
        ch = data[@pos + i];
        case ch
        when "["
          if escape
            token += ch
            escape = false
          else
            if(i > 0)
              gottoken = true
            else
              token += ch
            end
          end
        when "]"
          if escape
            token += ch
            escape = false
          else
            if(i == 0 )
              token += ch
            end
            gottoken = true
          end
        when "\\"
          if escape
            token += '\\\\'
            escape = false
          else
            escape = true
          end
        when " "
          if escape
            token += '\\n'
            escape = false
          else
            token += ch
          end
        when /[n{}<>^+*_=~\|\-]/
          if escape
            token += '\\' + ch
            escape = false
          else
            token += ch
          end
        else
          if escape
            token += ch
            escape = false
          else
            token += ch
          end
        end
        i += 1
      end

      if(i > 1)
        @pos += (i - 1)
      else
        @pos += 1
      end
      return token
    end

    def make_tree(parent)
      token = get_next_token.strip
      parts = Array.new

      while(token != "" && token != "]" )
        token_r = token.split(//)
        case token_r[0]
        when "["
          tl = token_r.length
          token_r = token_r[1, tl - 1]
          spaceat = token_r.index(" ")
          newparent  = -1

          if spaceat
            parts[0] = token_r[0, spaceat].join

            tl =token_r.length
            parts[1] = token_r[spaceat, tl - spaceat].join

            element = Element.new(@id, parent, parts[0], @level, @fontset, @fontsize)
            @id += 1
            @elist.add(element)
            newparent = element.id

            element = Element.new(@id, @id - 1, parts[1], @level + 1, @fontset, @fontsize)
            @id += 1
            @elist.add(element)
          else
            joined = token_r.join
            element = Element.new(@id, parent, joined, @level, @fontset,  @fontsize)
            @id += 1
            newparent = element.id
            @elist.add(element)
          end

          @level += 1
          make_tree(newparent)

        else
          if token.strip != ""
            element = Element.new(@id, parent, token, @level, @fontset, @fontsize)
            @id += 1
            @elist.add(element)
          end
        end

        token = get_next_token
      end
      @level -= 1
    end
  end
end

