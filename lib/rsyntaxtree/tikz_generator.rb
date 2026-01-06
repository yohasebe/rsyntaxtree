# frozen_string_literal: true

#==========================
# tikz_generator.rb
#==========================
#
# Generates TikZ/forest LaTeX code from parsed tree elements
# Copyright (c) 2007-2026 Yoichiro Hasebe <yohasebe@gmail.com>

module RSyntaxTree
  class TikZGenerator
    LATEX_ESCAPE_MAP = {
      '&' => '\\&',
      '%' => '\\%',
      '$' => '\\$',
      '#' => '\\#',
      '_' => '\\_',
      '{' => '\\{',
      '}' => '\\}',
      '~' => '\\textasciitilde{}',
      '^' => '\\textasciicircum{}'
    }.freeze

    def initialize(element_list, params)
      @element_list = element_list
      @params = params
    end

    # Generate TikZ forest code
    # @param standalone [Boolean] whether to include LaTeX preamble
    # @param font [String, nil] font name for XeLaTeX/fontspec (enables fontspec when specified)
    # @return [String] TikZ/forest code
    def generate(standalone: false, font: nil)
      tree_code = generate_tree(1)

      if standalone
        generate_standalone(tree_code, font: font)
      else
        generate_forest_only(tree_code)
      end
    end

    private

    def generate_standalone(tree_code, font: nil)
      if font
        <<~LATEX
          \\documentclass[border=10pt]{standalone}
          \\usepackage{forest}
          \\usepackage{fontspec}
          \\setmainfont{#{font}}

          \\begin{document}
          #{generate_forest_only(tree_code)}
          \\end{document}
        LATEX
      else
        <<~LATEX
          \\documentclass[border=10pt]{standalone}
          \\usepackage{forest}

          \\begin{document}
          #{generate_forest_only(tree_code)}
          \\end{document}
        LATEX
      end
    end

    def generate_forest_only(tree_code)
      <<~LATEX
        \\begin{forest}
        for tree={
          parent anchor=south,
          child anchor=north,
          align=center,
          base=top
        }
        #{tree_code}
        \\end{forest}
      LATEX
    end

    # Recursively generate tree structure
    def generate_tree(element_id, indent = 0)
      element = @element_list.get_id(element_id)
      return "" unless element

      label = extract_label(element)
      escaped_label = escape_latex(label)

      children = element.children
      indent_str = "  " * indent

      if children.empty?
        "#{indent_str}[#{escaped_label}]"
      else
        child_code = children.map { |child_id| generate_tree(child_id, indent + 1) }.join("\n")
        "#{indent_str}[#{escaped_label}\n#{child_code}\n#{indent_str}]"
      end
    end

    # Extract plain text label from element content
    def extract_label(element)
      content = element.content
      return "" if content.nil? || content.empty?

      # content is an array of hashes with :type and :elements
      texts = []
      content.each do |line|
        next unless line[:type] == :text

        line[:elements].each do |el|
          text = el[:text].to_s
          # Remove RSyntaxTree-specific whitespace block
          text = text.gsub("￭", " ")
          texts << text unless text.strip.empty?
        end
      end
      texts.join(" ")
    end

    # Escape LaTeX special characters
    def escape_latex(text)
      result = text.dup
      LATEX_ESCAPE_MAP.each do |char, escaped|
        result.gsub!(char, escaped)
      end
      result
    end
  end
end
