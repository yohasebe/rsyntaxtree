# frozen_string_literal: true

require "yaml"

# Turns the front matter of a gallery example into generator options.
# Shared by dev/generate_examples.rb and test/example_verify_test.rb so that
# a figure is never drawn with one set of options and tested with another.
module ExampleOptions
  module_function

  # Returns [name, opts] for an example file.
  def load(path)
    config = YAML.load_file(path)
    data = File.read(path).scan(/```([^`]+)```/m).last.first

    opts = DEFAULT_OPTS.dup
    name = nil
    config.each do |key, value|
      next if value.to_s == ""

      case key
      when "name"
        name = value
        opts[:name] = value
      when "color"
        opts[:color] = case value
                       when "modern", "on", "true"
                         "modern"
                       when "traditional"
                         "traditional"
                       when "gray", "grey"
                         "gray"
                       else
                         "off"
                       end
      when "hyphen"
        opts[:hyphen] = value
      when "linewidth", "line_width"
        opts[:linewidth] = value
      when "polyline"
        opts[:polyline] = value
      when "hide_default_connectors"
        opts[:hide_default_connectors] = value
      when "connector_height"
        opts[:vheight] = value
      when "symmetrization"
        opts[:symmetrize] = value
      when "connector"
        opts[:leafstyle] = value
      when "direction"
        opts[:direction] = value
      when "tidy"
        opts[:tidy] = value
      when "hspacing"
        opts[:hspacing] = value
      when "tidy_spacing"
        opts[:tidy_spacing] = value
      when "mirror"
        opts[:mirror] = value
      when "font"
        opts[:fontstyle] = case value
                           when /mono/i
                             "mono"
                           when /sans/i
                             "sans"
                           when /serif/i
                             "serif"
                           when /wqy|cjk/i
                             "cjk"
                           else
                             "sans"
                           end
      end
    end

    opts[:data] = data
    [name, opts]
  end
end
