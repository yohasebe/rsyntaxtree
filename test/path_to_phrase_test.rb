# frozen_string_literal: true

require "minitest/autorun"
require "minitest/pride"

require_relative "../lib/rsyntaxtree"
require_relative "../lib/rsyntaxtree/utils"

# A movement path to a phrase stops at the edge of everything the phrase
# holds, its shade included, rather than running in through its daughters.
class PathToPhraseTest < Minitest::Test
  TREE = "[CP [%NP+>1 [AP How tall] [NP a man]] [C did [NP ∅+1]]]"

  # The movement path's points, from the rounded polyline it is drawn as.
  def path_points(svg)
    d = svg[/<path d='(M[^']*)'[^>]*marker-end/m, 1]
    d.scan(/(-?[\d.]+),(-?[\d.]+)/).map { |x, y| [x.to_f, y.to_f] }
  end

  def shade(svg)
    x, y, w, h = svg.match(/<rect x='([-\d.e]+)' y='([-\d.e]+)' width='([-\d.e]+)' height='([-\d.e]+)' rx=/).captures.map(&:to_f)
    { left: x, top: y, right: x + w, bottom: y + h }
  end

  {
    "ttb" => ->(tip, box) { tip[1] > box[:bottom] && tip[0] > box[:left] && tip[0] < box[:right] },
    "btt" => ->(tip, box) { tip[1] < box[:top] && tip[0] > box[:left] && tip[0] < box[:right] },
    "ltr" => ->(tip, box) { tip[0] > box[:right] && tip[1] > box[:top] && tip[1] < box[:bottom] }
  }.each do |direction, outside|
    define_method "test_the_arrow_stops_outside_the_phrase_#{direction}" do
      svg = RSyntaxTree::RSGenerator.new(data: TREE, format: "svg", direction: direction).draw_svg
      points = path_points(svg)
      box = shade(svg)

      assert outside.call(points.last, box), "tip #{points.last.inspect} against #{box.inspect}"
      points.each_cons(2) do |a, b|
        mid = [(a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0]
        refute(mid[0] > box[:left] && mid[0] < box[:right] && mid[1] > box[:top] && mid[1] < box[:bottom],
               "the path runs through the phrase at #{mid.inspect}")
      end
    end
  end

  # One clearance from the shade as it is painted, the root's included,
  # whose edge sits closer in than other shades'.
  def test_the_tip_stands_one_clearance_from_a_root_shade
    gen = RSyntaxTree::RSGenerator.new(data: "[%S+>1 [A x+1] [B y]]", format: "svg", direction: "btt", hspacing: 3)
    svg = gen.draw_svg
    hctt = gen.instance_variable_get(:@global)[:height_connector_to_text]

    assert_in_delta shade(svg)[:top] - hctt, path_points(svg).last[1], 0.01
  end

  def test_a_path_to_a_word_still_ends_at_the_word
    svg = RSyntaxTree::RSGenerator.new(data: "[CP [NP who+>1] [C did [NP ∅+1]]]", format: "svg").draw_svg
    gen = RSyntaxTree::RSGenerator.new(data: "[CP [NP who+>1] [C did [NP ∅+1]]]", format: "svg")
    list = gen.send(:parsed_element_list)
    RSyntaxTree::SVGGraph.new(list, gen.instance_variable_get(:@params), gen.instance_variable_get(:@global)).svg_data
    who = list.get_elements.find { |e| e.raw_content == "who" }

    assert_in_delta who.vertical_indent + who.content_height + gen.instance_variable_get(:@global)[:height_connector_to_text],
                    path_points(svg).last[1], 0.5
  end
end
