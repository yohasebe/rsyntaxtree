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

    # Whether the raw space that split this token is what stopped it parsing.
    # Asked of the parser rather than reasoned about: the whole token, with its
    # spaces written as `<>`, either reads as one label or it does not.
    def space_is_the_cause?(token, parent)
      Element.new(-1, parent, token.gsub(" ", WHITESPACE_BLOCK), @level,
                  @fontset, @fontsize, @global, true)
      true
    rescue StandardError
      false
    end

    def parse
      make_tree(0);
      @elist.set_hierarchy
      restore_rule_names_without_a_rule
    end

    # A rule name names the step that produced a node from its daughters. A node
    # with no daughters is the product of no step, so what looked like a name is
    # a column of the label like any other, and it goes back.
    #
    # Whether a node will have daughters is not known where the label is read —
    # they arrive as later tokens — so the label is read first and put right
    # here, once the tree is built. Left alone, turning the option on deleted a
    # column: `[A\tfoo]` drew "A foo" with derivation off and "A" with it on,
    # and said nothing about the difference.
    def restore_rule_names_without_a_rule
      @elist.elements.each_with_index do |e, i|
        next if e.rule_name.nil? || e.rule_name.empty?
        next unless e.children.empty?
        next if e.label_with_rule_name.nil?

        restored = Element.new(e.id, e.parent, e.label_with_rule_name,
                               e.level, @fontset, @fontsize, @global)
        restored.children = e.children
        restored.type = e.type
        @elist.elements[i] = restored
      end
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
        # The characters a backslash may take, which is the grammar's own list
        # (Markup's `escaped` rule) plus the two letters that name a break. A
        # backslash before anything else is dropped here, and '#' was missing:
        # `\#` arrived at the grammar as a bare '#', which opens an enclosure,
        # so a label written with a hash in it lost the hash and everything
        # after it went inside brackets instead.
        when /[nt{}<>^+*_=~|%\-#]/
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
                Element.new(@id, parent, parts[0], @level, @fontset, @fontsize, @global, true)
              rescue RSTError => e
                # The first raw space splits a token into the node's label
                # and its children (that split is the notation's core rule,
                # so it stays). When the part before the space will not
                # parse, the likeliest story is that the space belongs
                # inside the label and cut a construct in two — say so,
                # unless a more specific cause is already known.
                #
                # Which of the two it is, the repair machinery has already
                # decided: it names a cause only when it has a repair it has
                # checked, and falls back to :invalid_markup when no single
                # repair worked. So a named cause is one a caller can act on,
                # and the space is a red herring; :invalid_markup is where the
                # space is the better story.
                #
                # This used to keep :bare_hyphen and relabel every other cause,
                # which left one error saying two things: the message naming an
                # unknown colour while the code and the hint talked about
                # spaces. A caller acting on the code — which is what the
                # structured errors are for — was sent to fix what was not
                # wrong.
                # Which story is right is not a thing to guess at: ask
                # whether the space is the one that breaks it. Put the whole
                # token back together with the spaces written as the notation
                # writes them, and try again. If it parses, the space was
                # cutting a construct in two and that is what to say. If it
                # fails the same way, the space is a red herring and the cause
                # already named is the one to keep.
                #
                # It used to keep :bare_hyphen and relabel every other cause,
                # so one error said two things: the message naming an unknown
                # colour while the code and the hint talked about spaces. A
                # caller acting on the code — which is what these are for —
                # was sent to fix what was not wrong.
                raise e unless space_is_the_cause?(token_r.join, parent)

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
              element = Element.new(@id, parent, joined, @level, @fontset, @fontsize, @global, true)
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
