# frozen_string_literal: true

#==========================
# format_converter.rb
#==========================
#
# Converts various tree notation formats to RSyntaxTree's bracket notation
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

module RSyntaxTree
  module FormatConverter
    module_function

    # Detect the format of the input string
    # @param text [String] the input tree notation
    # @return [Symbol] :penn or :bracket
    def detect_format(text)
      stripped = text.strip
      if stripped.start_with?('(') && !stripped.start_with?('([')
        :penn
      else
        :bracket
      end
    end

    # Convert any supported format to bracket notation
    # @param text [String] the input tree notation
    # @return [String] bracket notation
    def to_bracket(text)
      case detect_format(text)
      when :penn
        penn_to_bracket(text)
      else
        text
      end
    end

    # Convert Penn TreeBank format to bracket notation
    # Penn: (S (NP hello) (VP world))
    # Bracket: [S [NP hello] [VP world]]
    # Use \( and \) to include literal parentheses in text
    # @param text [String] Penn TreeBank notation
    # @return [String] bracket notation
    def penn_to_bracket(text)
      # Normalize whitespace (collapse multiple spaces/newlines to single space)
      normalized = text.gsub(/\s+/, ' ').strip

      # Protect escaped parentheses with placeholders
      result = normalized.gsub('\(', "\x00LPAREN\x00").gsub('\)', "\x00RPAREN\x00")

      # Replace structural parentheses with brackets
      result = result.gsub('(', '[').gsub(')', ']')

      # Restore escaped parentheses as literal parentheses
      result = result.gsub("\x00LPAREN\x00", '(').gsub("\x00RPAREN\x00", ')')

      # Clean up extra spaces after opening brackets
      result = result.gsub(/\[\s+/, '[')
      # Clean up extra spaces before closing brackets
      result = result.gsub(/\s+\]/, ']')

      result
    end
  end
end
