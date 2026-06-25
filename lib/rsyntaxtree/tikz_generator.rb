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
    # Default region shade color (bare '%') and the forced color in monochrome
    # (color off) mode; matches the SVG backend's gray.
    REGION_DEFAULT_COLOR = "gray"
    # Fill stays faint; the border reuses the same color at a higher opacity so
    # the region is clearly bounded in both color and black-and-white output.
    REGION_FILL_OPACITY = "0.2"
    REGION_STROKE_OPACITY = "0.55"

    # SVG/CSS extended color keywords -> hex. Used to resolve region shade color
    # names that xcolor does not define (so the generated LaTeX still compiles).
    CSS_COLORS = {
      "aliceblue" => "#f0f8ff", "antiquewhite" => "#faebd7", "aqua" => "#00ffff",
      "aquamarine" => "#7fffd4", "azure" => "#f0ffff", "beige" => "#f5f5dc",
      "bisque" => "#ffe4c4", "black" => "#000000", "blanchedalmond" => "#ffebcd",
      "blue" => "#0000ff", "blueviolet" => "#8a2be2", "brown" => "#a52a2a",
      "burlywood" => "#deb887", "cadetblue" => "#5f9ea0", "chartreuse" => "#7fff00",
      "chocolate" => "#d2691e", "coral" => "#ff7f50", "cornflowerblue" => "#6495ed",
      "cornsilk" => "#fff8dc", "crimson" => "#dc143c", "cyan" => "#00ffff",
      "darkblue" => "#00008b", "darkcyan" => "#008b8b", "darkgoldenrod" => "#b8860b",
      "darkgray" => "#a9a9a9", "darkgreen" => "#006400", "darkgrey" => "#a9a9a9",
      "darkkhaki" => "#bdb76b", "darkmagenta" => "#8b008b", "darkolivegreen" => "#556b2f",
      "darkorange" => "#ff8c00", "darkorchid" => "#9932cc", "darkred" => "#8b0000",
      "darksalmon" => "#e9967a", "darkseagreen" => "#8fbc8f", "darkslateblue" => "#483d8b",
      "darkslategray" => "#2f4f4f", "darkslategrey" => "#2f4f4f", "darkturquoise" => "#00ced1",
      "darkviolet" => "#9400d3", "deeppink" => "#ff1493", "deepskyblue" => "#00bfff",
      "dimgray" => "#696969", "dimgrey" => "#696969", "dodgerblue" => "#1e90ff",
      "firebrick" => "#b22222", "floralwhite" => "#fffaf0", "forestgreen" => "#228b22",
      "fuchsia" => "#ff00ff", "gainsboro" => "#dcdcdc", "ghostwhite" => "#f8f8ff",
      "gold" => "#ffd700", "goldenrod" => "#daa520", "gray" => "#808080",
      "green" => "#008000", "greenyellow" => "#adff2f", "grey" => "#808080",
      "honeydew" => "#f0fff0", "hotpink" => "#ff69b4", "indianred" => "#cd5c5c",
      "indigo" => "#4b0082", "ivory" => "#fffff0", "khaki" => "#f0e68c",
      "lavender" => "#e6e6fa", "lavenderblush" => "#fff0f5", "lawngreen" => "#7cfc00",
      "lemonchiffon" => "#fffacd", "lightblue" => "#add8e6", "lightcoral" => "#f08080",
      "lightcyan" => "#e0ffff", "lightgoldenrodyellow" => "#fafad2", "lightgray" => "#d3d3d3",
      "lightgreen" => "#90ee90", "lightgrey" => "#d3d3d3", "lightpink" => "#ffb6c1",
      "lightsalmon" => "#ffa07a", "lightseagreen" => "#20b2aa", "lightskyblue" => "#87cefa",
      "lightslategray" => "#778899", "lightslategrey" => "#778899", "lightsteelblue" => "#b0c4de",
      "lightyellow" => "#ffffe0", "lime" => "#00ff00", "limegreen" => "#32cd32",
      "linen" => "#faf0e6", "magenta" => "#ff00ff", "maroon" => "#800000",
      "mediumaquamarine" => "#66cdaa", "mediumblue" => "#0000cd", "mediumorchid" => "#ba55d3",
      "mediumpurple" => "#9370db", "mediumseagreen" => "#3cb371", "mediumslateblue" => "#7b68ee",
      "mediumspringgreen" => "#00fa9a", "mediumturquoise" => "#48d1cc", "mediumvioletred" => "#c71585",
      "midnightblue" => "#191970", "mintcream" => "#f5fffa", "mistyrose" => "#ffe4e1",
      "moccasin" => "#ffe4b5", "navajowhite" => "#ffdead", "navy" => "#000080",
      "oldlace" => "#fdf5e6", "olive" => "#808000", "olivedrab" => "#6b8e23",
      "orange" => "#ffa500", "orangered" => "#ff4500", "orchid" => "#da70d6",
      "palegoldenrod" => "#eee8aa", "palegreen" => "#98fb98", "paleturquoise" => "#afeeee",
      "palevioletred" => "#db7093", "papayawhip" => "#ffefd5", "peachpuff" => "#ffdab9",
      "peru" => "#cd853f", "pink" => "#ffc0cb", "plum" => "#dda0dd",
      "powderblue" => "#b0e0e6", "purple" => "#800080", "rebeccapurple" => "#663399",
      "red" => "#ff0000", "rosybrown" => "#bc8f8f", "royalblue" => "#4169e1",
      "saddlebrown" => "#8b4513", "salmon" => "#fa8072", "sandybrown" => "#f4a460",
      "seagreen" => "#2e8b57", "seashell" => "#fff5ee", "sienna" => "#a0522d",
      "silver" => "#c0c0c0", "skyblue" => "#87ceeb", "slateblue" => "#6a5acd",
      "slategray" => "#708090", "slategrey" => "#708090", "snow" => "#fffafa",
      "springgreen" => "#00ff7f", "steelblue" => "#4682b4", "tan" => "#d2b48c",
      "teal" => "#008080", "thistle" => "#d8bfd8", "tomato" => "#ff6347",
      "turquoise" => "#40e0d0", "violet" => "#ee82ee", "wheat" => "#f5deb3",
      "white" => "#ffffff", "whitesmoke" => "#f5f5f5", "yellow" => "#ffff00",
      "yellowgreen" => "#9acd32"
    }.freeze

    def generate(standalone: false, font: nil)
      tree_code = generate_tree(1)

      if standalone
        generate_standalone(tree_code, font: font)
      else
        generate_forest_only(tree_code)
      end
    end

    private

    # True when any node requests a region shade, so the preamble can pull in
    # the TikZ libraries (backgrounds, fit) that the shade nodes rely on.
    def any_region?
      @element_list.get_elements.any?(&:region)
    end

    def generate_standalone(tree_code, font: nil)
      # Region shades draw fitted nodes on the background layer, which needs
      # the backgrounds and fit TikZ libraries.
      region_libs = any_region? ? "\\usetikzlibrary{backgrounds,fit}\n" : ""
      if font
        <<~LATEX
          \\documentclass[border=10pt]{standalone}
          \\usepackage{forest}
          #{region_libs}\\usepackage{fontspec}
          \\setmainfont{#{font}}

          \\begin{document}
          #{generate_forest_only(tree_code)}
          \\end{document}
        LATEX
      else
        <<~LATEX
          \\documentclass[border=10pt]{standalone}
          \\usepackage{forest}
          #{region_libs}
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
      head = "#{escaped_label}#{region_option(element)}"

      children = element.children
      indent_str = "  " * indent

      if children.empty?
        "#{indent_str}[#{head}]"
      else
        child_code = children.map { |child_id| generate_tree(child_id, indent + 1) }.join("\n")
        "#{indent_str}[#{head}\n#{child_code}\n#{indent_str}]"
      end
    end

    # forest node option that paints a semi-transparent plane behind the whole
    # subtree governed by +element+ (region shade). Uses forest's "fit to=tree"
    # on the background layer so the plane sits below the tree. Empty string
    # when the node has no region shade.
    def region_option(element)
      return "" unless element.region

      # An explicit shade color is always honored; bare '%' falls back to gray.
      color = element.region_color ? tikz_region_color(element.region_color) : REGION_DEFAULT_COLOR
      ", tikz={\\scoped[on background layer]{\\node[fill=#{color}, " \
        "fill opacity=#{REGION_FILL_OPACITY}, draw=#{color}, " \
        "draw opacity=#{REGION_STROKE_OPACITY}, rounded corners, inner sep=4pt, " \
        "fit to=tree]{};}}"
    end

    # Map an RSyntaxTree color (name or #hex) to a TikZ fill color expression.
    # SVG/CSS color names and #hex codes are resolved to a TikZ inline rgb
    # expression so the figure compiles without depending on which color names
    # xcolor happens to define (e.g. "lightblue" is valid in SVG but not in
    # xcolor). Unknown names are passed through as a best effort.
    def tikz_region_color(region_color)
      return REGION_DEFAULT_COLOR if region_color.nil? || region_color.empty?

      hex = if region_color.start_with?("#")
              region_color
            else
              CSS_COLORS[region_color.downcase]
            end
      rgb = hex_to_rgb(hex) if hex
      if rgb
        "{rgb,255:red,#{rgb[0]};green,#{rgb[1]};blue,#{rgb[2]}}"
      else
        region_color
      end
    end

    # Convert a #hex color (3- or 6-digit) to an [r, g, b] array, or nil if it
    # is not a recognizable hex string.
    def hex_to_rgb(hex)
      h = hex.to_s.sub(/\A#/, "")
      h = h.chars.map { |c| c * 2 }.join if h.length == 3
      return nil unless h.length == 6 && h =~ /\A[0-9a-fA-F]{6}\z/

      [h[0, 2].to_i(16), h[2, 2].to_i(16), h[4, 2].to_i(16)]
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
