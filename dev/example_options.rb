# frozen_string_literal: true

require "yaml"

# Turns the front matter of a gallery example into generator options.
# Shared by dev/generate_examples.rb and test/example_verify_test.rb so that
# a figure is never drawn with one set of options and tested with another.
module ExampleOptions
  module_function

  # Front matter key to generator option. The names differ because the front
  # matter keeps the names the gallery has always used; the values do not,
  # and are passed through untouched. RSGenerator resolves aliases such as
  # colour "on" and leaf style "none" itself, so normalising them here would
  # be a second copy of a rule that already exists, free to drift from it.
  KEYS = {
    "name" => :name,
    "color" => :color,
    "hyphen" => :hyphen,
    "linewidth" => :linewidth,
    "line_width" => :linewidth,
    "polyline" => :polyline,
    "hide_default_connectors" => :hide_default_connectors,
    "connector_height" => :vheight,
    "connector" => :leafstyle,
    "direction" => :direction,
    "derivation" => :derivation,
    "tidy" => :tidy,
    "hspacing" => :hspacing,
    "mirror" => :mirror,
    "shear" => :shear,
    "shear_plane" => :shear_plane,
    "vmargin" => :vmargin,
    "font" => :fontstyle
  }.freeze

  # Returns [name, opts] for an example file.
  def load(path)
    config = YAML.load_file(path)
    data = File.read(path).scan(/```([^`]+)```/m).last.first

    opts = DEFAULT_OPTS.dup
    config.each do |key, value|
      next if value.to_s == ""

      option = KEYS[key]
      next unless option

      # The gallery names a font the way the interface lists it, "Noto Sans
      # Mono"; the option takes the same name as an identifier.
      value = value.downcase.tr(" ", "-") if option == :fontstyle
      opts[option] = value
    end

    opts[:data] = data
    [opts[:name], opts]
  end
end
