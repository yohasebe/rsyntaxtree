# frozen_string_literal: true

#==========================
# string_parser.rb
#==========================
#
# Parses a phrase into leafs and nodes and store the result in an element list
# (see element_list.rb)
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

require_relative 'elementlist'
require_relative 'element'
require_relative 'utils'

module RSyntaxTree
  class StringParser
    attr_accessor :data, :elist, :pos, :id, :level

    def initialize(str, fontset, fontsize, global)
      @global = global
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
        result = if num_padding.positive?
                   WHITESPACE_BLOCK * num_padding
                 else
                   WHITESPACE_BLOCK
                 end
        result
      end

      @data = string # Store it for later...
      fontset[:family] = fontset[:family_cjk] if @data.contains_cjk?
      @elist = ElementList.new # Initialize internal element list
      @pos = 0 # Position in the sentence
      @id = 1 # ID for the next element
      @level = 0 # Level in the diagram
      @fontset = fontset
      @fontsize = fontsize
    end

    def self.valid?(data)
      raise RSTError.new(+"Error: input text is empty", code: :empty_input, retryable: false) if data.empty?

      if /\[\s*\]/m =~ data
        raise RSTError.new(+"Error: inside the brackets is empty", code: :empty_brackets,
                           hint: "A pair of brackets has no label between them. Give the node a label, or remove the pair.",
                           retryable: true)
      end

      text = data.strip
      text_r = text.split(//)
      open_br = []
      close_br = []
      escape = false
      text_r.each do |chr|
        if chr == "\\"
          escape = if escape
                     false
                   else
                     true
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
          break if open_br.length < close_br.length
        end
        escape = false
      end

      # No brackets at all is a label on its own, which draws as a single
      # leaf; only a count that does not match is a mistake.
      if open_br.length == close_br.length
        true
      else
        raise RSTError.new(+"Error: open and close brackets do not match", code: :unbalanced_brackets,
                           hint: "Count the brackets: every '[' needs one ']'. A bracket meant as text is written \\[ or \\].",
                           retryable: true)
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

      return "" if (@pos + 1) >= data.length

      escape = false
      while ((@pos + i) < data.length) && !gottoken
        ch = data[@pos + i]
        case ch
        when "["
          if escape
            token += '\\['  # Preserve as escaped bracket
            escape = false
          elsif i.positive?
            gottoken = true
          else
            token += ch
          end
        when "]"
          if escape
            token += '\\]'  # Preserve as escaped bracket
            escape = false
          else
            token += ch if i.zero?
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
        when /[nt{}<>^+*_=~|%-]/
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

      @pos += if i > 1
                i - 1
              else
                1
              end
      token
    end

    def make_tree(parent)
      token = get_next_token.strip
      parts = []

      while token != "" && token != "]"
        token_r = token.split(//)
        case token_r[0]
        when "["
          # Check for escaped square brackets
          if token =~ /\A\\\[/ || token =~ /\A\\\]/
            # Treat escaped brackets as regular text
            element = Element.new(@id, parent, token, @level, @fontset, @fontsize, @global)
            @id += 1
            @elist.add(element)
          else
            # Existing processing below
            tl = token_r.length
            token_r = token_r[1, tl - 1]
            spaceat = token_r.index(" ")
            newparent = -1

            if spaceat
              parts[0] = token_r[0, spaceat].join
              tl = token_r.length
              parts[1] = token_r[spaceat, tl - spaceat].join

              element = begin
                Element.new(@id, parent, parts[0], @level, @fontset, @fontsize, @global)
              rescue RSTError => e
                # The first raw space splits a token into the node's label
                # and its children (that split is the notation's core rule,
                # so it stays). When the part before the space will not
                # parse, the likeliest story is that the space belongs
                # inside the label and cut a construct in two — say so,
                # unless a more specific cause is already known.
                raise e if e.code == :bare_hyphen

                raise RSTError.new(e.message,
                                   code: :label_split,
                                   label: e.label,
                                   position: e.position,
                                   hint: "A raw space split this into a label and its children. If the space belongs inside the label, write it as <> (e.g. 'a<>toy').",
                                   retryable: true)
              end
              @id += 1
              @elist.add(element)
              newparent = element.id

              element = Element.new(@id, @id - 1, parts[1], @level + 1, @fontset, @fontsize, @global)
              @id += 1
            else
              joined = token_r.join
              element = Element.new(@id, parent, joined, @level, @fontset, @fontsize, @global)
              @id += 1
              newparent = element.id
            end
            @elist.add(element)
            @level += 1
            make_tree(newparent)
          end
        else
          if token.strip != ""
            element = Element.new(@id, parent, token, @level, @fontset, @fontsize, @global)
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
