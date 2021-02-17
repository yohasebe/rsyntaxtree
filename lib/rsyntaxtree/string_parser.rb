#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#==========================
# string_parser.rb
#==========================
#
# Parses a phrase into leafs and nodes and store the result in an element list
# (see element_list.rb)
#
# This file is part of RSyntaxTree, which is a ruby port of Andre Eisenbach's
# excellent program phpSyntaxTree.
#
# Copyright (c) 2007-2021 Yoichiro Hasebe <yohasebe@gmail.com>
# Copyright (c) 2003-2004 Andre Eisenbach <andre@ironcreek.net>

require 'elementlist'
require 'element'

def escape_high_ascii(string)
  html = ""
  string.length.times do |i|
    ch = string[i]
    if(ch < 127)
      html += ch.chr
    else
      html += sprintf("&#%d;", ch)
    end
  end  
  html
end

class StringParser

  attr_accessor :data, :elist, :pos, :id, :level, :tncnt
  def initialize(str)
    # Clean up the data a little to make processing easier
    string = str.gsub(/\t/, "") rescue ""
    string.gsub!(/\s+/, " ")
    string.gsub!(/\] \[/, "][")
    string.gsub!(/ \[/, "[")

    @data = string # Store it for later...
    @elist = ElementList.new # Initialize internal element list 
    @pos = 0 # Position in the sentence
    @id = 1 # ID for the next element
    @level = 0 # Level in the diagram
    @tncnt = Hash.new # Node type counts
  end

  # caution: quick and dirty solution      
  def valid?
    if(@data.length < 1)
      return false
    end

    if /\[\s*\]/m =~ @data
      return false  
    end

    if /\[\_/ =~ @data
      return false
    end

    text = @data.strip
    text_r = text.split(//)
    open_br, close_br = [], []
    escape = false
    text_r.each do |chr|
      if chr == "\\"
        escape = true
      elsif chr == '[' && !escape
        open_br.push(chr)
      elsif chr == ']' && !escape
        close_br.push(chr)
        if open_br.length < close_br.length
          break
        end
      elsif escape
        escape = false
      end
    end

    return false unless open_br.length == close_br.length
    # make_tree(0)
    # return false if @tncnt.empty?
    # @tncnt.each do |key, value|
    #   return false if key == ""
    # end
    return true
  end 

  def parse
    make_tree(0);
  end

  def get_elementlist
    @elist;
  end

  def auto_subscript
    elements = @elist.get_elements
    tmpcnt   = Hash.new
    elements.each do |element|
      if(element.type == ETYPE_NODE)
        count = 1
        content = element.content

        if @tncnt[content]
          count = @tncnt[content]
        end

        if(count > 1)
          if tmpcnt[content]
            tmpcnt[content] += 1
          else
            tmpcnt[content] = 1
          end

          element.content += ("_" + tmpcnt[content].to_s)
        end

      end
    end  
    @tncnt
  end
 
  def count_node(name)
    name = name.strip
    if @tncnt[name]
      @tncnt[name] += 1
    else
      @tncnt[name] = 1
    end
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
        escape = true
      when /[\n\r]/
        gottoken = false # same as do nothing  
      else
        token += ch
        escape = false if escape
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
          parts[0] = parts[0].gsub("<>", " ")

          tl =token_r.length
          parts[1] = token_r[spaceat, tl - spaceat].join
          parts[1] = parts[1].gsub("<>", " ")

          element = Element.new(@id, parent, parts[0], @level)
          @id += 1
          @elist.add(element)
          newparent = element.id
          count_node(parts[0])

          element = Element.new(@id, @id - 1, parts[1], @level + 1 )
          @id += 1          
          @elist.add(element)
        else
          joined = token_r.join.gsub("<>", " ")
          element = Element.new(@id, parent, joined, @level)
          @id += 1          
          newparent = element.id
          @elist.add(element)
          count_node(joined)
        end 

        @level += 1
        make_tree(newparent)

      else
        if token.strip != ""
          element = Element.new(@id, parent, token, @level)
          @id += 1          
          @elist.add(element)
          count_node(token)
        end
      end

      token = get_next_token
    end
    @level -= 1
  end
end

